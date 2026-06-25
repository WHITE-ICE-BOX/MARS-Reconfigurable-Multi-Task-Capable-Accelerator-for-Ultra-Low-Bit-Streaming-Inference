# ===========================================================================
# [交接導向註解]
# 主訓練入口（1W1A QAT + Conv-Adapter 遷移）。流程：AI_model_train 階段。
# mode=full_ft(全網路微調) / adapter(凍結 backbone 只訓 adapter)；支援任意 net_bit。
# 輸出：checkpoint(.tar) + Final Best Accuracy。adapter 幾何由 --adapter_* 旗標決定。
# 用法見 AI_model_train/README.md 第四節。
# ===========================================================================

"""
Multi-bitwidth training driver for the bitwidth-vs-adapter experiment.

Mirrors the logic of /home/esl/barkie/bnn_pynq/bnn_pynq/bnn_pynq_train.py but:
- Uses claude/models_bitwidth/ (parametrizable CNV with QuantReLU for >=2-bit acts).
- Uses claude/cfg_bitwidth/ configs (cnv_{N}w{N}a.ini for N in 1,2,4,8,16,32).
- Does NOT modify any original-project file.
- Adds a transfer mode flag covering: pretrain / full_ft / adapter / frozen_only.
"""

import os
import sys
import argparse
import random
import shutil
import numpy as np

THIS_DIR = os.path.dirname(os.path.abspath(__file__))
PROJ_ROOT = os.path.abspath(os.path.join(THIS_DIR, '..'))
if PROJ_ROOT not in sys.path:
    sys.path.insert(0, PROJ_ROOT)

import tarfile
import urllib.request

import torch
import torchvision
from packaging.version import parse
from torchvision import transforms
from torchvision.datasets import CIFAR10, MNIST, SVHN, STL10, FashionMNIST, ImageFolder
from torch.utils.data import DataLoader

from trainer import Trainer
from models_bitwidth import model_with_cfg_bitwidth
from models_bitwidth.CNV_param import cnv_param


def set_global_seed(seed):
    # 把所有亂數源（python / numpy / torch CPU+GPU）與 cuDNN 設成完全決定性，
    # 確保論文數字「同 seed 可重現」。deterministic=True + benchmark=False 關掉
    # cuDNN 的非決定性演算法；CUBLAS_WORKSPACE_CONFIG 是 CUDA 決定性 matmul 的必要環境變數。
    if seed is not None:
        print(f"[Seed] Resetting Global Seed to {seed}...")
        random.seed(seed)
        np.random.seed(seed)
        torch.manual_seed(seed)
        torch.cuda.manual_seed(seed)
        torch.cuda.manual_seed_all(seed)
        torch.backends.cudnn.deterministic = True
        torch.backends.cudnn.benchmark = False
        os.environ["CUBLAS_WORKSPACE_CONFIG"] = ":4096:8"
        torch.use_deterministic_algorithms(True, warn_only=True)


def seed_worker(worker_id):
    worker_seed = torch.initial_seed() % 2**32
    np.random.seed(worker_seed)
    random.seed(worker_seed)


def print_model_details(model):
    total = sum(p.numel() for p in model.parameters())
    trainable = sum(p.numel() for p in model.parameters() if p.requires_grad)
    print(f"[Model Stats] Total Params: {total}")
    print(f"[Model Stats] Trainable Params: {trainable}")
    return total


class MirrorMNIST(MNIST):
    if parse(torchvision.__version__) < parse('0.9.1'):
        resources = [
            ("https://ossci-datasets.s3.amazonaws.com/mnist/train-images-idx3-ubyte.gz", "f68b3c2dcbeaaa9fbdd348bbdeb94873"),
            ("https://ossci-datasets.s3.amazonaws.com/mnist/train-labels-idx1-ubyte.gz", "d53e105ee54ea40749a09fcbcd1e9432"),
            ("https://ossci-datasets.s3.amazonaws.com/mnist/t10k-images-idx3-ubyte.gz", "9fb629c4189551a2d022fa330f9573f3"),
            ("https://ossci-datasets.s3.amazonaws.com/mnist/t10k-labels-idx1-ubyte.gz", "ec29112dd5afa0611ce80d1b7f02629c")]


class CommonSVHN(SVHN):
    def __init__(self, root, train=True, transform=None, target_transform=None, download=False):
        split = "train" if train else "test"
        super().__init__(root=root, split=split, transform=transform, target_transform=target_transform, download=download)


class CommonSTL10(STL10):
    """STL10: 96x96 RGB → resized to 32x32; 10 classes."""
    def __init__(self, root, train=True, transform=None, target_transform=None, download=False):
        split = "train" if train else "test"
        super().__init__(root=root, split=split, transform=transform,
                         target_transform=target_transform, download=download)


class CommonFashionMNIST(FashionMNIST):
    """FashionMNIST: 28x28 grayscale → resized to 32x32 + converted to RGB; 10 classes."""
    pass


CINIC10_URL = "https://datashare.ed.ac.uk/bitstream/handle/10283/3192/CINIC-10.tar.gz"


def download_and_extract_cinic10(root):
    """Download + extract CINIC-10 (skip if already extracted)."""
    train_dir = os.path.join(root, "train")
    if os.path.isdir(train_dir) and os.path.isdir(os.path.join(train_dir, "airplane")):
        return root
    tar_path = os.path.join(root, "CINIC-10.tar.gz")
    os.makedirs(root, exist_ok=True)
    if not os.path.exists(tar_path):
        print(f"Downloading CINIC-10 to {tar_path}...")
        urllib.request.urlretrieve(CINIC10_URL, tar_path)
    print(f"Extracting CINIC-10...")
    with tarfile.open(tar_path, "r:gz") as tf:
        tf.extractall(path=root)
    return root


def get_dataloader(args):
    # 目標：所有資料集都吐出 32x32x3 張量以吻合 CNV backbone 輸入幾何。
    # 各資料集差異：CIFAR/SVHN/CINIC 原生 32x32；STL10 需 Resize(96->32)；
    # FashionMNIST 需 Resize + Grayscale->3 通道。train_transform 含資料增強
    # （RandomCrop/Flip），to_tensor 為測試用（不增強）。
    to_tensor = transforms.Compose([transforms.ToTensor()])
    if args.dataset == 'CIFAR10':
        train_transform = transforms.Compose([
            transforms.RandomCrop(32, padding=4),
            transforms.RandomHorizontalFlip(),
            transforms.ToTensor()])
        builder = CIFAR10
    elif args.dataset == 'SVHN':
        train_transform = transforms.Compose([
            transforms.RandomCrop(32, padding=4),
            transforms.ToTensor()])
        builder = CommonSVHN
    elif args.dataset == 'MNIST':
        train_transform = to_tensor
        builder = MirrorMNIST
    elif args.dataset == 'STL10':
        train_transform = transforms.Compose([
            transforms.Resize(32),
            transforms.RandomCrop(32, padding=4),
            transforms.RandomHorizontalFlip(),
            transforms.ToTensor()])
        to_tensor = transforms.Compose([transforms.Resize(32), transforms.ToTensor()])
        builder = CommonSTL10
    elif args.dataset == 'FashionMNIST':
        train_transform = transforms.Compose([
            transforms.Resize(32),
            transforms.Grayscale(num_output_channels=3),
            transforms.RandomCrop(32, padding=4),
            transforms.RandomHorizontalFlip(),
            transforms.ToTensor()])
        to_tensor = transforms.Compose([
            transforms.Resize(32),
            transforms.Grayscale(num_output_channels=3),
            transforms.ToTensor()])
        builder = CommonFashionMNIST
    elif args.dataset == 'CINIC10':
        # CINIC10 用 ImageFolder 讀官方 train / test 兩個子集（各 90k，互斥、無洩漏）；
        # 官方還有 valid 子集（90k）此處不使用。總計 270k = 90k×3。
        cinic_dir = download_and_extract_cinic10(args.datadir)
        train_transform = transforms.Compose([
            transforms.RandomCrop(32, padding=4),
            transforms.RandomHorizontalFlip(),
            transforms.ToTensor()])
        train_set = ImageFolder(root=os.path.join(cinic_dir, "train"), transform=train_transform)
        test_set = ImageFolder(root=os.path.join(cinic_dir, "test"), transform=to_tensor)
        g = torch.Generator()
        if args.random_seed is not None:
            g.manual_seed(args.random_seed)
        train_loader = DataLoader(train_set, batch_size=args.batch_size, shuffle=True,
                                  num_workers=args.num_workers, worker_init_fn=seed_worker, generator=g)
        test_loader = DataLoader(test_set, batch_size=args.batch_size, shuffle=False,
                                 num_workers=args.num_workers, worker_init_fn=seed_worker, generator=g)
        return train_loader, test_loader
    else:
        raise Exception(f"Dataset not supported: {args.dataset}")

    train_set = builder(root=args.datadir, train=True, download=True, transform=train_transform)
    test_set = builder(root=args.datadir, train=False, download=True, transform=to_tensor)

    g = torch.Generator()
    if args.random_seed is not None:
        g.manual_seed(args.random_seed)

    train_loader = DataLoader(train_set, batch_size=args.batch_size, shuffle=True,
                              num_workers=args.num_workers, worker_init_fn=seed_worker, generator=g)
    test_loader = DataLoader(test_set, batch_size=args.batch_size, shuffle=False,
                             num_workers=args.num_workers, worker_init_fn=seed_worker, generator=g)
    return train_loader, test_loader


def parse_args():
    p = argparse.ArgumentParser(description='Multi-bitwidth BNN trainer (claude/)')
    p.add_argument('--mode', type=str, default='pretrain',
                   choices=['pretrain', 'full_ft', 'adapter', 'frozen_only'],
                   help='pretrain: train backbone on source; '
                        'full_ft: fine-tune whole net on target; '
                        'adapter: freeze backbone + train adapter on target; '
                        'frozen_only: freeze backbone, train only FC3 (linear probe)')
    p.add_argument('--net_bit', type=int, required=True, choices=[1, 2, 4, 8, 16, 32])
    p.add_argument('--adapter_bit_width', type=int, default=1)
    p.add_argument('--adapter_kernel', type=int, default=3, choices=[1, 3],
                   help='Down-conv kernel size in QuantConvAdapter (3=software, 1=hw-friendly)')
    p.add_argument('--adapter_act', type=str, default='relu', choices=['relu', 'signed'],
                   help='Adapter internal activation: relu (v3 default) or signed QuantIdentity (v4)')
    p.add_argument('--adapter_alpha', type=str, default='per_channel',
                   choices=['per_channel', 'scalar'],
                   help='Adapter alpha parameter shape: per_channel (v3) or scalar (v2/v4)')
    p.add_argument('--adapter_bias', action='store_true',
                   help='Enable bias=True + Int8Bias on adapter down conv (v5)')
    p.add_argument('--adapter_mid_basis', type=str, default='out', choices=['in', 'out'],
                   help='mid_channels formula: in (HW-friendly, v1/v2 style) or out (v3-v6 default)')
    p.add_argument('--num_branches', type=int, default=0)
    p.add_argument('--no_rc', action='store_true')
    p.add_argument('--rc_bit_width', type=int, default=8)

    p.add_argument('--dataset', type=str, default='CIFAR10')
    p.add_argument('--datadir', type=str, default=os.path.join(PROJ_ROOT, 'data'))
    p.add_argument('--experiments', type=str,
                   default=os.path.join(THIS_DIR, 'paper_results_bitwidth', 'experiments'))
    p.add_argument('--experiment_name', type=str, default='default')

    p.add_argument('--finetune_checkpoint', type=str, default=None,
                   help='Backbone checkpoint to load (for transfer modes)')

    p.add_argument('--epochs', type=int, default=1)
    p.add_argument('--batch_size', type=int, default=100)
    p.add_argument('--num_workers', type=int, default=4)
    p.add_argument('--lr', type=float, default=0.02)
    p.add_argument('--weight_decay', type=float, default=0)
    p.add_argument('--optim', type=str, default='ADAM')
    p.add_argument('--loss', type=str, default='SqrHinge')
    p.add_argument('--scheduler', type=str, default='FIXED')
    p.add_argument('--milestones', type=str, default='30,40')
    p.add_argument('--momentum', type=float, default=0.9)
    p.add_argument('--random_seed', type=int, default=2024)
    p.add_argument('--gpus', type=str, default='0')
    p.add_argument('--log_freq', type=int, default=50)
    p.add_argument('--dry_run', action='store_true')
    p.add_argument('--resume', type=str, default=None)
    p.add_argument('--strict', action='store_true')

    # Flags expected by the existing Trainer; we keep them off here.
    p.add_argument('--export_qonnx', action='store_true')
    p.add_argument('--export_qcdq_onnx', action='store_true')
    p.add_argument('--detect_nan', action='store_true')
    p.add_argument('--pretrained', action='store_true')
    p.add_argument('--export_finn_assets', action='store_true')
    p.add_argument('--teacher_checkpoint', type=str, default=None)
    p.add_argument('--distill_alpha', type=float, default=0.1)
    p.add_argument('--distill_temp', type=float, default=10.0)
    p.add_argument('--network', type=str, default='CNV')

    args = p.parse_args()

    # mode 決定 backbone 是否凍結（這是 PEFT vs full fine-tune 的關鍵）：
    #   adapter      → 凍結 backbone，只訓 adapter（num_branches 預設補成 1）→ MARS 的做法
    #   frozen_only  → 凍結 backbone，只訓最後分類層（linear probe，當下限對照）
    #   pretrain / full_ft → 不凍結，整網路一起訓（pretrain 訓 backbone；full_ft 為上界）
    if args.mode == 'adapter':
        args.freeze_backbone = True
        if args.num_branches == 0:
            args.num_branches = 1  # Single 1-bit adapter
    elif args.mode == 'frozen_only':
        args.freeze_backbone = True
    else:
        args.freeze_backbone = False

    return args


def build_model(args):
    """依指定 bit-width 建 CNV，並（選擇性）注入 Adapter。"""
    # 1) 先載入該位元寬度的 CNV 設定（cnv_1w1a / cnv_2w2a ... 的 .ini）。
    cfg_name = f'cnv_{args.net_bit}w{args.net_bit}a'
    _, cfg = model_with_cfg_bitwidth(cfg_name)

    # 2) 若要 Adapter（num_branches>0），把命令列的 adapter 旗標寫進 cfg 的 [ADAPTER] 區段。
    #    cnv_param() 會讀這些值決定每層 Adapter 的「幾何」：
    #      KERNEL_SIZE(1/3)、ALPHA_MODE(scalar/per_channel)、MID_BASIS(in=Cin/4 / out=Cout/4)、
    #      USE_RC(殘差校正開關)、NUM_BRANCHES(M)。
    #    → deployed 幾何 = kernel1 + scalar + in；accuracy-best = kernel3 + per_channel + out。
    if args.num_branches > 0:
        if not cfg.has_section('ADAPTER'):
            cfg.add_section('ADAPTER')
        cfg.set('ADAPTER', 'NUM_BRANCHES', str(args.num_branches))   # M：平行分支數
        cfg.set('ADAPTER', 'BIT_WIDTH', str(args.adapter_bit_width))
        cfg.set('ADAPTER', 'USE_RC', str(not args.no_rc))            # RC（down-conv Int8 bias）
        cfg.set('ADAPTER', 'RC_BIT_WIDTH', str(args.rc_bit_width))
        cfg.set('ADAPTER', 'KERNEL_SIZE', str(args.adapter_kernel))
        cfg.set('ADAPTER', 'ACT_MODE', args.adapter_act)
        cfg.set('ADAPTER', 'ALPHA_MODE', args.adapter_alpha)
        cfg.set('ADAPTER', 'USE_BIAS', str(args.adapter_bias))       # =RC 開關的實際旗標
        cfg.set('ADAPTER', 'MID_BASIS', args.adapter_mid_basis)

    # 3) 建模型前重設 seed（確保權重初始化可重現），再依 cfg 實例化 CNV(+Adapter)。
    set_global_seed(args.random_seed)
    model = cnv_param(cfg)
    if args.num_branches > 0:
        model.use_adapter = True   # 開啟 forward 時的 adapter 旁路
    return model


def main():
    # 訓練主流程：解析參數 → 建模型(含/不含 adapter) → 載資料 → 交給 Trainer 跑。
    args = parse_args()
    set_global_seed(args.random_seed)

    model = build_model(args)                              # CNV(+Adapter)，依 mode 決定凍結
    train_loader, test_loader = get_dataloader(args)       # 資料統一成 32x32x3

    trainer = Trainer(model, train_loader, test_loader, args)
    print("--- Pre-training Check ---")
    print_model_details(model)                             # 印總參數量 / 可訓練參數量（看 adapter 開銷）

    best_acc = trainer.train_model()                       # 跑訓練，回傳最佳驗證準確率
    print(f"Final Best Accuracy: {best_acc}%")             # ← runner/腳本就是抓這行擷取結果

    # If pretraining a backbone, copy best.tar to claude/pretrained_backbones/
    if args.mode == 'pretrain' and args.dataset == 'CIFAR10':
        backbone_dir = os.path.join(THIS_DIR, 'pretrained_backbones')
        os.makedirs(backbone_dir, exist_ok=True)
        src = os.path.join(trainer.checkpoints_dir_path, "best.tar")
        dst = os.path.join(backbone_dir, f"cifar10_{args.net_bit}w{args.net_bit}a.tar")
        if os.path.exists(src):
            shutil.copy2(src, dst)
            print(f"[Pretrain] Backbone copied -> {dst}")
        else:
            print(f"[Pretrain] WARNING: no best.tar at {src}")


if __name__ == '__main__':
    main()
