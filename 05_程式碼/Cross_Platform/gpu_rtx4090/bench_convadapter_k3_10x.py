import os
"""Cross-platform benchmark for the PRIOR-ART Conv-Adapter (3x3, 1W1A).

GPU/Jetson deployment-level baseline for Table 5.15: runs the k3 (3x3 down)
single-branch Conv-Adapter at 1W1A on SVHN, batch 1000, 10,000 images, n=10.
Reuses build_svhn_loader / PowerMonitor / timing from benchmark_svhn.py so it
stays consistent with benchmark_svhn_10x.py. Model is built via
models_bitwidth.CNV_param.cnv_param (QuantConvAdapter, kernel=3), matching the
Transfer_k3_b1_adapter_e50 checkpoint exactly.
"""
import sys, os, time, statistics, configparser
import torch

BENCH_DIR = os.environ.get("BENCH_DIR", os.path.dirname(os.path.abspath(__file__)))
CLAUDE_DIR = os.environ.get("CLAUDE_SRC", ".")
for p in (BENCH_DIR, CLAUDE_DIR):
    if p not in sys.path:
        sys.path.insert(0, p)

from benchmark_svhn import build_svhn_loader, PowerMonitor
from models_bitwidth.CNV_param import cnv_param

CKPT = os.environ.get("CKPT",
    CLAUDE_DIR + "/paper_results_bitwidth/v3_compare_50ep_2026-05-03/"
    "experiments/Transfer_k3_b1_adapter_e50/checkpoints/best.tar")
LABEL = os.environ.get("LABEL", "ConvAdapter_k3_b1")
BATCH = 1000
TARGET = 10000
REPEATS = int(os.environ.get("REPEATS", "10"))


def make_cfg():
    cfg = configparser.ConfigParser()
    cfg.add_section('QUANT')
    cfg.set('QUANT', 'WEIGHT_BIT_WIDTH', '1')
    cfg.set('QUANT', 'ACT_BIT_WIDTH', '1')
    cfg.set('QUANT', 'IN_BIT_WIDTH', '8')
    cfg.add_section('MODEL')
    cfg.set('MODEL', 'NUM_CLASSES', '10')
    cfg.set('MODEL', 'IN_CHANNELS', '3')
    cfg.add_section('ADAPTER')
    cfg.set('ADAPTER', 'NUM_BRANCHES', '1')
    cfg.set('ADAPTER', 'BIT_WIDTH', '1')
    cfg.set('ADAPTER', 'RC_BIT_WIDTH', '8')
    cfg.set('ADAPTER', 'USE_RC', 'False')
    cfg.set('ADAPTER', 'KERNEL_SIZE', '3')
    cfg.set('ADAPTER', 'ACT_MODE', 'relu')
    cfg.set('ADAPTER', 'ALPHA_MODE', 'per_channel')
    cfg.set('ADAPTER', 'USE_BIAS', 'False')
    cfg.set('ADAPTER', 'MID_BASIS', 'out')
    return cfg


def load_model():
    ckpt = torch.load(CKPT, map_location='cuda', weights_only=False)
    sd = ckpt['state_dict'] if (isinstance(ckpt, dict) and 'state_dict' in ckpt) else ckpt
    m = cnv_param(make_cfg())
    missing, unexpected = m.load_state_dict(sd, strict=False)
    miss_real = [k for k in missing if 'num_batches_tracked' not in k]
    if miss_real or unexpected:
        print("WARN missing:", miss_real[:8], "... unexpected:", list(unexpected)[:8])
    return m.cuda().eval()


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


print("device:", torch.cuda.get_device_name(0))
pm = PowerMonitor(); print("power mode:", pm.mode)
_, testloader = build_svhn_loader(batch_size=BATCH, num_workers=2)
model = load_model()
wu = torch.randn(BATCH, 3, 32, 32, device='cuda')
with torch.no_grad():
    for _ in range(50):
        _ = model(wu)
torch.cuda.synchronize()

runs = []
for t in range(REPEATS):
    r = run_once(model, testloader, pm); runs.append(r)
    print(f"  [{LABEL}] run {t+1:2d}/{REPEATS}: fps_dev={r['fps_dev']:.2f}  "
          f"fps_wall={r['fps_wall']:.2f}  P={r['power']:.2f}W  acc={r['acc']:.2f}")

print("\n" + "=" * 74)
print(f"  {LABEL}  |  SVHN {TARGET}  |  batch {BATCH}  |  n={REPEATS}")
print("=" * 74)
print(f"{'metric':<28}{'mean':>11}{'std':>10}{'min':>11}{'max':>11}")
print("-" * 74)
for k, lbl in [("fps_dev", "FPS device(H2D+GPU+D2H)"), ("fps_wall", "FPS end-to-end"),
               ("power", "Power (W)"), ("eff_dev", "Eff device (img/s/W)"),
               ("eff_wall", "Eff end-to-end (img/s/W)"),
               ("lat_wall", "Latency e2e (ms)"), ("acc", "Accuracy (%)")]:
    m, s, lo, hi = st(runs, k)
    print(f"{lbl:<28}{m:>11.3f}{s:>10.3f}{lo:>11.3f}{hi:>11.3f}")
print("=" * 74)
print("DONE_K3_10X")
