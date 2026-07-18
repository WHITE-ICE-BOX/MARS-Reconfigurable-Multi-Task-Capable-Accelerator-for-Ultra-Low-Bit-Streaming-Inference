"""Unified 10-repeat cross-platform benchmark (RTX 4090 / Jetson Orin NX).

Runs BOTH models (backbone-only + RC_m1 adapter) on SVHN, batch 1000, 10,000
images, 10 repeats each; reports FPS + power + efficiency + latency as
mean / std / min / max. Reuses the proven model/loader/PowerMonitor from
benchmark_svhn.py (same dir) so it stays consistent with the existing flow.

FPS mapping to the FPGA table:
  fps_device (H2D + GPU + D2H) <-> FPGA "FPS Driver+FPGA" (the table headline)
  fps_wall   (incl. Python loop) <-> FPGA "FPS end-to-end"

Run (in the project dir):
  python3 benchmark_svhn_10x.py
"""
import sys, os, time, statistics
import torch
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from benchmark_svhn import cnv, create_mock_config, build_svhn_loader, PowerMonitor
# NOTE: thop/count_ops deliberately NOT used -- it mis-counts brevitas quantized
# layers AND its total_ops/total_params buffers corrupt a second model's
# state_dict load. GOPS is derived post-hoc from one unified ops/img convention.

BATCH = 1000
TARGET = 10000
REPEATS = 10
MODELS = [("backbone", "Cifar10_backbone.tar"),
          ("adapter_RC_m1", "RC_m1_full.tar")]


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
    fps_wall = seen / wall; fps_dev = seen / tot_dev; fps_comp = seen / tot_compute
    return dict(acc=100.0 * ok / seen, fps_wall=fps_wall, fps_dev=fps_dev, fps_comp=fps_comp,
                power=avg_p, max_power=max_p,
                eff_wall=(fps_wall / avg_p if avg_p > 0 else 0.0),
                eff_dev=(fps_dev / avg_p if avg_p > 0 else 0.0),
                lat_wall=1000.0 / fps_wall, lat_dev=1000.0 / fps_dev)


def st(runs, key):
    v = [r[key] for r in runs]
    return statistics.mean(v), (statistics.stdev(v) if len(v) > 1 else 0.0), min(v), max(v)


print("GPU:", torch.cuda.get_device_name(0))
pm = PowerMonitor(); print("power mode:", pm.mode)
_, testloader = build_svhn_loader(batch_size=BATCH, num_workers=2)

for name, tar in MODELS:
    if not os.path.exists(tar):
        print(f"SKIP {name}: {tar} not found"); continue
    model, has_ad = load_model(tar)
    wu = torch.randn(BATCH, 3, 32, 32, device='cuda')      # warmup once
    with torch.no_grad():
        for _ in range(50):
            _ = model(wu)
    torch.cuda.synchronize()

    runs = []
    for t in range(REPEATS):
        r = run_once(model, testloader, pm); runs.append(r)
        print(f"  [{name}] run {t+1:2d}/{REPEATS}: fps_dev={r['fps_dev']:.2f}  "
              f"fps_wall={r['fps_wall']:.2f}  P={r['power']:.2f}W  acc={r['acc']:.2f}")

    print("\n" + "=" * 74)
    print(f"  {name}  (adapter={has_ad})  |  SVHN {TARGET}  |  batch {BATCH}  |  n={REPEATS}")
    print("=" * 74)
    print(f"{'metric':<28}{'mean':>11}{'std':>10}{'min':>11}{'max':>11}")
    print("-" * 74)
    for k, lbl in [("fps_dev", "FPS device(H2D+GPU+D2H)"), ("fps_wall", "FPS end-to-end"),
                   ("power", "Power (W)"), ("eff_dev", "Eff device (img/s/W)"),
                   ("eff_wall", "Eff end-to-end (img/s/W)"),
                   ("lat_dev", "Latency device (ms)"), ("acc", "Accuracy (%)")]:
        m, s, lo, hi = st(runs, k)
        print(f"{lbl:<28}{m:>11.3f}{s:>10.3f}{lo:>11.3f}{hi:>11.3f}")
    print("=" * 74)

print("DONE_GPU_10X")
