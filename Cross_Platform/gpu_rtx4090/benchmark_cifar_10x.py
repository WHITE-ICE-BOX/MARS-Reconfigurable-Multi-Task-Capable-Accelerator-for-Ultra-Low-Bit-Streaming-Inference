"""10-repeat cross-platform benchmark, BACKBONE-only on CIFAR-10 (Table 5.11).

Backbone is CIFAR-trained, so it is benchmarked on CIFAR-10 (meaningful accuracy
~81%, unlike the ~11% it gives on SVHN). CIFAR-10 10,000 test images, batch 1000,
10 repeats; reports FPS + power + efficiency + latency as mean/std/min/max.
Preprocessing = ToTensor (/255), matching the FPGA /255 NCHW path.

Run (in the project dir): python3 benchmark_cifar_10x.py
"""
import sys, os, time, statistics
import torch
import torchvision
import torchvision.transforms as T
from torch.utils.data import DataLoader
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from benchmark_svhn import cnv, create_mock_config, PowerMonitor

BATCH = 1000
TARGET = 10000
REPEATS = 10
TAR = "Cifar10_backbone.tar"


def build_cifar_loader(batch_size=BATCH, num_workers=2):
    tf = T.Compose([T.ToTensor()])
    testset = torchvision.datasets.CIFAR10(root='./data', train=False, download=True, transform=tf)
    return DataLoader(testset, batch_size=batch_size, shuffle=False,
                      num_workers=num_workers, pin_memory=True, drop_last=True)


def load_model(tar):
    ckpt = torch.load(tar, map_location='cuda', weights_only=False)
    sd = ckpt['state_dict'] if (isinstance(ckpt, dict) and 'state_dict' in ckpt) else ckpt
    has_adapter = any('adapters.' in k for k in sd.keys())
    m = cnv(create_mock_config(use_adapter=has_adapter))
    m.load_state_dict(sd)
    return m.cuda().eval(), has_adapter


def run_once(model, testloader, power):
    tot_compute = 0.0; tot_dev = 0.0; ok = 0; seen = 0
    power.start()
    wall0 = time.time()
    with torch.no_grad():
        for xc, yc in testloader:
            if seen >= TARGET:
                break
            bs = yc.size(0); rem = TARGET - seen
            if bs > rem:
                xc = xc[:rem]; yc = yc[:rem]; bs = rem
            b0 = time.time()
            x = xc.cuda(non_blocking=True); y = yc.cuda(non_blocking=True); torch.cuda.synchronize()
            c0 = time.time(); out = model(x); torch.cuda.synchronize(); c1 = time.time()
            pred = out.argmax(1).cpu(); ylab = y.cpu(); torch.cuda.synchronize()
            b1 = time.time()
            tot_compute += (c1 - c0); tot_dev += (b1 - b0)
            ok += (pred == ylab).sum().item(); seen += bs
    torch.cuda.synchronize(); wall1 = time.time()
    avg_p, max_p = power.stop()
    wall = wall1 - wall0
    fps_wall = seen / wall; fps_dev = seen / tot_dev
    return dict(acc=100.0 * ok / seen, fps_wall=fps_wall, fps_dev=fps_dev,
                power=avg_p, max_power=max_p,
                eff_wall=(fps_wall / avg_p if avg_p > 0 else 0.0),
                eff_dev=(fps_dev / avg_p if avg_p > 0 else 0.0),
                lat_wall=1000.0 / fps_wall, lat_dev=1000.0 / fps_dev)


def st(runs, key):
    v = [r[key] for r in runs]
    return statistics.mean(v), (statistics.stdev(v) if len(v) > 1 else 0.0), min(v), max(v)


print("GPU:", torch.cuda.get_device_name(0))
pm = PowerMonitor(); print("power mode:", pm.mode)
testloader = build_cifar_loader()
model, has_ad = load_model(TAR)
wu = torch.randn(BATCH, 3, 32, 32, device='cuda')
with torch.no_grad():
    for _ in range(50):
        _ = model(wu)
torch.cuda.synchronize()

runs = []
for t in range(REPEATS):
    r = run_once(model, testloader, pm); runs.append(r)
    print(f"  [backbone/cifar10] run {t+1:2d}/{REPEATS}: fps_wall={r['fps_wall']:.2f}  "
          f"P={r['power']:.2f}W  acc={r['acc']:.2f}")

print("\n" + "=" * 74)
print(f"  backbone (adapter={has_ad})  |  CIFAR-10 {TARGET}  |  batch {BATCH}  |  n={REPEATS}")
print("=" * 74)
print(f"{'metric':<28}{'mean':>11}{'std':>10}{'min':>11}{'max':>11}")
print("-" * 74)
for k, lbl in [("fps_wall", "FPS end-to-end"), ("fps_dev", "FPS device(H2D+GPU+D2H)"),
               ("power", "Power (W)"), ("eff_wall", "Eff end-to-end (img/s/W)"),
               ("eff_dev", "Eff device (img/s/W)"), ("lat_wall", "Latency e2e (ms)"),
               ("acc", "Accuracy (%)")]:
    m, s, lo, hi = st(runs, k)
    print(f"{lbl:<28}{m:>11.3f}{s:>10.3f}{lo:>11.3f}{hi:>11.3f}")
print("=" * 74)
print("DONE_CIFAR_10X")
