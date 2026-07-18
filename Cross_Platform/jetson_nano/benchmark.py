import torch
import torch.nn as nn
from torch.nn import BatchNorm1d, BatchNorm2d, MaxPool2d, Module, ModuleList
import time
import threading
import glob
import configparser
import os

import torchvision
import torchvision.transforms as transforms
from torch.utils.data import DataLoader

from brevitas.core.restrict_val import RestrictValueType
from brevitas.nn import QuantConv2d, QuantIdentity, QuantLinear
from brevitas.quant.solver import BiasQuantSolver

try:
    from common import CommonActQuant, CommonWeightQuant, CommonQuant
    from tensor_norm import TensorNorm
except ImportError:
    try:
        from brevitas_examples.bnn_pynq.models.common import CommonActQuant, CommonWeightQuant, CommonQuant
        from brevitas_examples.bnn_pynq.models.tensor_norm import TensorNorm
    except ImportError:
        print("❌ 警告: 找不到 common 或 tensor_norm 模組！請確認您是在專案根目錄執行此腳本。")
        exit(1)

CNV_OUT_CH_POOL = [(64, False), (64, True), (128, False), (128, True), (256, False), (256, False)]
INTERMEDIATE_FC_FEATURES = [(256, 512), (512, 512)]
LAST_FC_IN_FEATURES = 512
POOL_SIZE = 2
KERNEL_SIZE = 3


class Int8Bias(CommonQuant, BiasQuantSolver):
    bit_width = 8
    requires_input_scale = False
    requires_weight_scale = False
    scaling_const = 1.0


class QuantAdapter(Module):
    def __init__(self, in_channels, out_channels, reduction=4, bit_width=1, rc_bit_width=8):
        super(QuantAdapter, self).__init__()
        reduced_channels = max(1, in_channels // reduction)
        bias_quantizer = Int8Bias if rc_bit_width == 8 else None

        self.down = QuantConv2d(
            in_channels=in_channels, out_channels=reduced_channels, kernel_size=1,
            bias=True, bias_quant=bias_quantizer, weight_quant=CommonWeightQuant, weight_bit_width=bit_width
        )
        self.act = QuantIdentity(act_quant=CommonActQuant, bit_width=bit_width)
        self.up = QuantConv2d(
            in_channels=reduced_channels, out_channels=out_channels, kernel_size=1,
            bias=False, weight_quant=CommonWeightQuant, weight_bit_width=bit_width
        )

    def forward(self, x):
        return self.up(self.act(self.down(x)))


class MultiBranchAdapter(Module):
    def __init__(self, in_channels, out_channels, num_branches=1, bit_width=1, rc_bit_width=8, use_rc=True):
        super(MultiBranchAdapter, self).__init__()
        self.use_rc = use_rc
        self.branches = ModuleList()
        self.alphas = nn.ParameterList()

        for _ in range(num_branches):
            self.branches.append(QuantAdapter(
                in_channels, out_channels, bit_width=bit_width, rc_bit_width=rc_bit_width
            ))
            self.alphas.append(nn.Parameter(torch.tensor(1.0)))

    def forward(self, x):
        out = 0
        for i in range(len(self.branches)):
            branch_out = self.branches[i](x)
            alpha_val = self.alphas[i] if self.training else float(self.alphas[i])
            out = out + branch_out * alpha_val
        return out


class CNV(Module):
    def __init__(self, num_classes, weight_bit_width, act_bit_width, in_bit_width, in_ch, adapter_config=None):
        super(CNV, self).__init__()
        self.conv_features = ModuleList()
        self.linear_features = ModuleList()
        self.adapters = ModuleList()
        self.use_adapter = adapter_config is not None

        self.conv_features.append(QuantIdentity(
            act_quant=CommonActQuant, bit_width=in_bit_width, min_val=-1.0, max_val=1.0 - 2.0 ** (-7),
            narrow_range=False, restrict_scaling_type=RestrictValueType.POWER_OF_TWO))

        for i, (out_ch, is_pool_enabled) in enumerate(CNV_OUT_CH_POOL):
            self.conv_features.append(QuantConv2d(
                kernel_size=KERNEL_SIZE, in_channels=in_ch, out_channels=out_ch, bias=False,
                weight_quant=CommonWeightQuant, weight_bit_width=weight_bit_width))

            if self.use_adapter and i > 0:
                self.adapters.append(MultiBranchAdapter(
                    in_channels=in_ch, out_channels=out_ch, num_branches=adapter_config['num_branches'],
                    bit_width=adapter_config['bit_width'], rc_bit_width=adapter_config['rc_bit_width'],
                    use_rc=adapter_config.get('use_rc', True)
                ))
            elif self.use_adapter:
                self.adapters.append(nn.Identity())

            in_ch = out_ch
            self.conv_features.append(BatchNorm2d(in_ch, eps=1e-4))
            self.conv_features.append(QuantIdentity(act_quant=CommonActQuant, bit_width=act_bit_width))
            if is_pool_enabled:
                self.conv_features.append(MaxPool2d(kernel_size=POOL_SIZE))

        for in_features, out_features in INTERMEDIATE_FC_FEATURES:
            self.linear_features.append(QuantLinear(
                in_features=in_features, out_features=out_features, bias=False,
                weight_quant=CommonWeightQuant, weight_bit_width=weight_bit_width))
            self.linear_features.append(BatchNorm1d(out_features, eps=1e-4))
            self.linear_features.append(QuantIdentity(act_quant=CommonActQuant, bit_width=act_bit_width))

        self.linear_features.append(QuantLinear(
            in_features=LAST_FC_IN_FEATURES, out_features=num_classes, bias=False,
            weight_quant=CommonWeightQuant, weight_bit_width=weight_bit_width))
        self.linear_features.append(TensorNorm())

        for m in self.modules():
            if isinstance(m, QuantConv2d) or isinstance(m, QuantLinear):
                torch.nn.init.uniform_(m.weight.data, -1, 1)

    def forward(self, x):
        x = 2.0 * x - torch.tensor([1.0], device=x.device)
        if not self.use_adapter:
            for mod in self.conv_features:
                x = mod(x)
        else:
            adapter_idx = 0
            x = self.conv_features[0](x)
            ptr = 1
            for i, (_, is_pool_enabled) in enumerate(CNV_OUT_CH_POOL):
                x_in = x
                x_conv = self.conv_features[ptr](x)
                ptr += 1
                if i > 0:
                    x_adp = self.adapters[adapter_idx](x_in)
                    x = x_conv + x_adp[:, :, 1:-1, 1:-1]
                else:
                    x = x_conv
                adapter_idx += 1
                x = self.conv_features[ptr](x)
                ptr += 1
                x = self.conv_features[ptr](x)
                ptr += 1
                if is_pool_enabled:
                    x = self.conv_features[ptr](x)
                    ptr += 1
        x = x.view(x.shape[0], -1)
        for mod in self.linear_features:
            x = mod(x)
        return x


def cnv(cfg):
    weight_bit_width = cfg.getint('QUANT', 'WEIGHT_BIT_WIDTH')
    act_bit_width = cfg.getint('QUANT', 'ACT_BIT_WIDTH')
    in_bit_width = cfg.getint('QUANT', 'IN_BIT_WIDTH')
    num_classes = cfg.getint('MODEL', 'NUM_CLASSES')
    in_channels = cfg.getint('MODEL', 'IN_CHANNELS')

    adapter_config = None
    if cfg.has_section('ADAPTER'):
        num_branches = cfg.getint('ADAPTER', 'NUM_BRANCHES')
        if num_branches > 0:
            adapter_config = {
                'num_branches': num_branches,
                'bit_width': cfg.getint('ADAPTER', 'BIT_WIDTH'),
                'rc_bit_width': cfg.getint('ADAPTER', 'RC_BIT_WIDTH'),
                'use_rc': cfg.getboolean('ADAPTER', 'USE_RC', fallback=True)
            }

    return CNV(
        weight_bit_width=weight_bit_width, act_bit_width=act_bit_width, in_bit_width=in_bit_width,
        num_classes=num_classes, in_ch=in_channels, adapter_config=adapter_config)


class PowerMonitor:
    def __init__(self):
        self.keep_running = True
        self.power_readings = []
        self.mode = "Unknown"
        self.tegra_power_file = None

        try:
            import pynvml
            pynvml.nvmlInit()
            self.nvml_handle = pynvml.nvmlDeviceGetHandleByIndex(0)
            self.mode = "Server (NVML)"
        except Exception:
            patterns = [
                "/sys/bus/i2c/drivers/ina3221x/*/iio:device*/in_power0_input",
                "/sys/bus/i2c/drivers/ina3221x/*/hwmon/hwmon*/power1_input",
                "/sys/class/hwmon/hwmon*/power1_input"
            ]
            for pattern in patterns:
                matches = glob.glob(pattern)
                if matches:
                    self.tegra_power_file = matches[0]
                    self.mode = "Jetson Nano (Sysfs)"
                    break

    def _read_power(self):
        if self.mode == "Server (NVML)":
            import pynvml
            try:
                return pynvml.nvmlDeviceGetPowerUsage(self.nvml_handle) / 1000.0
            except Exception:
                return 0.0
        elif self.mode == "Jetson Nano (Sysfs)":
            try:
                with open(self.tegra_power_file, 'r') as f:
                    return float(f.read().strip()) / 1000.0
            except Exception:
                return 0.0
        return 0.0

    def start(self):
        self.keep_running = True
        self.power_readings = []
        self.thread = threading.Thread(target=self._monitor_loop)
        self.thread.start()

    def _monitor_loop(self):
        while self.keep_running:
            p = self._read_power()
            if p > 0:
                self.power_readings.append(p)
            time.sleep(0.1)

    def stop(self):
        self.keep_running = False
        self.thread.join()
        if self.power_readings:
            return sum(self.power_readings) / len(self.power_readings), max(self.power_readings)
        return 0.0, 0.0


def create_mock_config(use_adapter=False):
    cfg = configparser.ConfigParser()
    cfg.add_section('QUANT')
    cfg.set('QUANT', 'WEIGHT_BIT_WIDTH', '1')
    cfg.set('QUANT', 'ACT_BIT_WIDTH', '1')
    cfg.set('QUANT', 'IN_BIT_WIDTH', '8')

    cfg.add_section('MODEL')
    cfg.set('MODEL', 'NUM_CLASSES', '10')
    cfg.set('MODEL', 'IN_CHANNELS', '3')

    if use_adapter:
        cfg.add_section('ADAPTER')
        cfg.set('ADAPTER', 'NUM_BRANCHES', '1')
        cfg.set('ADAPTER', 'BIT_WIDTH', '1')
        cfg.set('ADAPTER', 'RC_BIT_WIDTH', '8')
        cfg.set('ADAPTER', 'USE_RC', 'True')

    return cfg


def build_cifar10_loader(batch_size=100, num_workers=0):
    transform = transforms.Compose([
        transforms.ToTensor()
    ])

    testset = torchvision.datasets.CIFAR10(
        root='./data',
        train=False,
        download=True,
        transform=transform
    )

    testloader = DataLoader(
        testset,
        batch_size=batch_size,
        shuffle=False,
        num_workers=num_workers,
        pin_memory=True,
        drop_last=True
    )
    return testset, testloader


# ==========================================
# 新增: 自動計算 MACs 與 OPs 的輔助函式
# ==========================================
def count_ops(model, input_size=(1, 3, 32, 32)):
    try:
        from thop import profile
        import warnings
        with warnings.catch_warnings():
            warnings.simplefilter("ignore")
            dummy_input = torch.randn(input_size).cuda()
            macs, _ = profile(model, inputs=(dummy_input, ), verbose=False)
        ops = macs * 2  # 1 MAC = 1 Multiply + 1 Add = 2 OPs
        return ops, macs
    except ImportError:
        print("⚠️ 警告: 找不到 `thop` 模組，將使用固定的估算值。")
        print("💡 建議使用 `pip install thop` 來獲取根據您模型架構產生的精確運算量。")
        # 如果沒有 thop，給一個大約的 fallback 值 (假設普通 CNV 約 110M MACs)
        estimated_macs = 110_000_000 
        return estimated_macs * 2, estimated_macs


def evaluate_accuracy(model, testloader, total_images_limit=10000):
    print(f"\n📦 正在用 CIFAR-10 測試準確率 (目標: {total_images_limit} 筆)...")

    correct = 0
    total = 0

    with torch.no_grad():
        for inputs, labels in testloader:
            inputs = inputs.cuda(non_blocking=True)
            labels = labels.cuda(non_blocking=True)

            outputs = model(inputs)
            predicted = outputs.argmax(dim=1)

            current_bs = labels.size(0)
            remaining = total_images_limit - total
            if current_bs > remaining:
                predicted = predicted[:remaining]
                labels = labels[:remaining]
                current_bs = remaining

            total += current_bs
            correct += (predicted == labels).sum().item()

            if total >= total_images_limit:
                break

    accuracy = 100.0 * correct / total
    print(f"✅ 完成 {total} 筆 CIFAR-10 推論，準確率: {accuracy:.2f}%")
    return accuracy, total


def benchmark_gpu_fair(model, testloader, total_images_limit=10000, power_monitor=None, ops_per_img=0):
    print("\n" + "=" * 40)
    print("階段二：GPU 公平 benchmark（對齊 FPGA 標準）")
    print("=" * 40)

    total_copy_h2d = 0.0
    total_compute = 0.0
    total_copy_d2h = 0.0
    total_device_time = 0.0
    total_ok = 0
    total_seen = 0

    # 預熱
    print("🔥 開始 GPU 預熱...")
    warmup = torch.randn(100, 3, 32, 32, device='cuda')
    with torch.no_grad():
        for _ in range(50):
            _ = model(warmup)
    torch.cuda.synchronize()

    print("⏱️ 效能測試開始...")

    if power_monitor is not None:
        power_monitor.start()

    wall_start = time.time()

    with torch.no_grad():
        for inputs_cpu, labels_cpu in testloader:
            if total_seen >= total_images_limit:
                break

            current_bs = labels_cpu.size(0)
            remaining = total_images_limit - total_seen
            if current_bs > remaining:
                inputs_cpu = inputs_cpu[:remaining]
                labels_cpu = labels_cpu[:remaining]
                current_bs = remaining

            batch_start = time.time()

            # Host -> Device
            t0 = time.time()
            inputs = inputs_cpu.cuda(non_blocking=True)
            labels = labels_cpu.cuda(non_blocking=True)
            torch.cuda.synchronize()
            t1 = time.time()

            # GPU compute only
            t2 = time.time()
            outputs = model(inputs)
            torch.cuda.synchronize()
            t3 = time.time()

            # Device -> Host
            t4 = time.time()
            predicted = outputs.argmax(dim=1)
            predicted_cpu = predicted.cpu()
            labels_back_cpu = labels.cpu()
            torch.cuda.synchronize()
            t5 = time.time()

            batch_end = time.time()

            total_copy_h2d += (t1 - t0)
            total_compute += (t3 - t2)
            total_copy_d2h += (t5 - t4)
            total_device_time += (batch_end - batch_start)

            total_ok += (predicted_cpu == labels_back_cpu).sum().item()
            total_seen += current_bs

    torch.cuda.synchronize()
    wall_end = time.time()

    if power_monitor is not None:
        avg_power, max_power = power_monitor.stop()
    else:
        avg_power, max_power = 0.0, 0.0

    total_wall_time = wall_end - wall_start
    acc = 100.0 * total_ok / total_seen

    fps_wall = total_seen / total_wall_time
    fps_device = total_seen / total_device_time if total_device_time > 0 else 0.0
    fps_compute = total_seen / total_compute if total_compute > 0 else 0.0

    # ==========================================
    # 新增: GOPS 計算
    # GOPS = (每張影像的 OPs * 每秒處理張數) / 10^9
    # ==========================================
    gops_device = (ops_per_img * fps_device) / 1e9
    gops_compute = (ops_per_img * fps_compute) / 1e9

    avg_batch_latency_ms = (total_device_time / (total_seen / testloader.batch_size)) * 1000.0
    avg_img_latency_ms = (total_device_time / total_seen) * 1000.0

    efficiency_device = fps_device / avg_power if avg_power > 0 else 0.0
    efficiency_compute = fps_compute / avg_power if avg_power > 0 else 0.0

    gopsw_device = gops_device / avg_power if avg_power > 0 else 0.0
    gopsw_compute = gops_compute / avg_power if avg_power > 0 else 0.0

    print("\n" + "=" * 40)
    print("📊 最終成果報告 (可直接用於簡報)")
    print("=" * 40)
    print(f"🎯 模型準確率          : {acc:.2f} % (以 {total_seen} 筆 CIFAR-10 樣本計算)")
    print(f"🚀 總處理影像數        : {total_seen} images")
    print(f"⏱️ End-to-End 時間     : {total_wall_time:.4f} 秒")
    print(f"🚀 End-to-End FPS      : {fps_wall:.2f} img/s")
    print(f"🚀 Device FPS          : {fps_device:.2f} img/s (H2D + GPU + D2H)")
    print(f"🚀 Pure Compute FPS    : {fps_compute:.2f} img/s (GPU forward only)")
    print(f"🧮 Device GOPS         : {gops_device:.2f} GOPS")
    print(f"🧮 Compute GOPS        : {gops_compute:.2f} GOPS")
    print(f"⏱️ 平均每 batch 延遲   : {avg_batch_latency_ms:.4f} ms")
    print(f"⏱️ 平均每張影像延遲    : {avg_img_latency_ms:.4f} ms")
    print(f"📦 H2D 總時間          : {total_copy_h2d:.4f} 秒")
    print(f"🧠 GPU forward 總時間  : {total_compute:.4f} 秒")
    print(f"📤 D2H 總時間          : {total_copy_d2h:.4f} 秒")

    if power_monitor is not None and power_monitor.mode != "Unknown":
        print(f"⚡ 平均功耗            : {avg_power:.2f} W (峰值: {max_power:.2f} W)")
        print(f"🏆 Device 能效         : {efficiency_device:.2f} img/s/W")
        print(f"🏆 Compute 能效        : {efficiency_compute:.2f} img/s/W")
        print(f"💎 Device GOPS/W       : {gopsw_device:.2f} GOPS/W")
        print(f"💎 Compute GOPS/W      : {gopsw_compute:.2f} GOPS/W")
    else:
        print("⚡ 平均功耗            : 無法讀取 (無法計算 GOPS/W)")
    print("=" * 40)


def main():
    if not torch.cuda.is_available():
        print("❌ 錯誤: 找不到 CUDA。")
        return

    print(f"🚀 偵測到 GPU: {torch.cuda.get_device_name(0)}")
    monitor = PowerMonitor()
    print(f"🔌 功耗讀取模式: {monitor.mode}")

    tar_filename = "Cifar10_backbone.tar"
    print(f"🔄 正在讀取 {tar_filename}...")

    try:
        checkpoint = torch.load(tar_filename, map_location='cuda', weights_only=False)
        state_dict = checkpoint['state_dict'] if (isinstance(checkpoint, dict) and 'state_dict' in checkpoint) else checkpoint

        has_adapter = any('adapters.' in k for k in state_dict.keys())
        print(f"🔎 自動偵測結果：模型 {'[包含] ✅' if has_adapter else '[不包含] ❌'} Adapter 架構")

        print("🏗️ 正在初始化對應的模型架構...")
        model = cnv(create_mock_config(use_adapter=has_adapter))
        model.load_state_dict(state_dict)
        print("✅ 權重載入成功！")

    except Exception as e:
        print(f"❌ 載入失敗: {e}")
        return

    model = model.cuda()
    model.eval()

    # ==========================================
    # 新增: 在開始跑測試前，先計算模型的基礎運算量
    # ==========================================
    ops_per_img, macs_per_img = count_ops(model)
    print(f"🧮 模型解析: 單張影像運算量為 {ops_per_img / 1e6:.2f} MOPs ({macs_per_img / 1e6:.2f} MMACs)")

    BATCH_SIZE = 100
    TARGET_IMAGES = 10000

    testset, testloader = build_cifar10_loader(batch_size=BATCH_SIZE, num_workers=0)

    print("\n" + "=" * 40)
    print("階段一：CIFAR-10 準確率測試")
    print("=" * 40)
    acc, total_images = evaluate_accuracy(model, testloader, total_images_limit=TARGET_IMAGES)

    benchmark_gpu_fair(
        model=model,
        testloader=testloader,
        total_images_limit=total_images,
        power_monitor=monitor,
        ops_per_img=ops_per_img  # 將算好的運算量傳給 benchmark 函式
    )


if __name__ == "__main__":
    main()