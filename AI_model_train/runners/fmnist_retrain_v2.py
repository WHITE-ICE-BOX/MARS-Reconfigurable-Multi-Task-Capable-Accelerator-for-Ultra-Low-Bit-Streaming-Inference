import sys
#!/usr/bin/env python3
"""Controlled FMNIST-source 1-bit configC (accuracy-best) retrain for Table 5.5.
Exactly reproduces run_configC_cross.build_adapter (BIT=1, kernel3/relu/per-ch/mid=out, RC=--adapter_bias),
but with fresh experiment dirs so nothing is skipped, one job per cell (no full_ft duplication).
16 cells = 4 targets x M1-4, all RC. GPU1 (A6000). parallel=4.
"""
import os, sys, subprocess, threading, re
from concurrent.futures import ThreadPoolExecutor, as_completed

R = os.environ.get("MARS_TRAIN_ROOT", ".")
PROJ = os.path.abspath(os.path.join(R, '..'))
PY = sys.executable
TRAIN = os.path.join(R, "bnn_pynq_train_bitwidth.py")
BB = os.path.join(R, "pretrained_backbones", "fashionmnist_1w1a.tar")
OUT = os.path.join(R, "paper_results_bitwidth", "fashionmnist_configC_cross_v2")
EXP = os.path.join(OUT, "experiments"); LOGS = os.path.join(OUT, "logs")
os.makedirs(EXP, exist_ok=True); os.makedirs(LOGS, exist_ok=True)

TARGETS = ["SVHN", "CIFAR10", "STL10", "CINIC10"]   # SVHN first (the flagged column)
MS = [1, 2, 3, 4]
GPU = "1"
PARALLEL = 4
LOCK = threading.Lock()
results = {}

def cell_cmd(target, M):
    name = f"Transfer_fashionmnist2oCC_{target}_M{M}_rc_e200_v2"
    return [PY, '-u', TRAIN,
        '--mode','adapter','--net_bit','1','--dataset',target,
        '--finetune_checkpoint',BB,
        '--epochs','200','--lr','0.005','--scheduler','STEP','--milestones','100,150',
        '--batch_size','100','--num_workers','2','--random_seed','2024',
        '--experiments',EXP,'--experiment_name',name,
        '--num_branches',str(M),'--adapter_bit_width','1',
        '--adapter_kernel','3','--adapter_act','relu','--adapter_alpha','per_channel',
        '--adapter_mid_basis','out','--no_rc','--adapter_bias']

def run_cell(target, M):
    label = f"{target}_M{M}"
    logp = os.path.join(LOGS, f"{label}.log")
    env = os.environ.copy(); env['CUDA_VISIBLE_DEVICES'] = GPU
    with open(logp,'w') as fp:
        p = subprocess.Popen(cell_cmd(target,M), stdout=fp, stderr=subprocess.STDOUT, cwd=PROJ, env=env)
        rc = p.wait()
    acc = None
    try:
        with open(logp) as f: txt = f.read()
        m = re.findall(r'Final Best Accuracy:\s*([0-9.]+)%', txt)
        if m: acc = float(m[-1])
    except Exception: pass
    with LOCK:
        results[label] = (acc, rc)
        with open(os.path.join(OUT,'results_v2.csv'),'w') as cf:
            cf.write("dataset,M,rc,acc,returncode\n")
            for t in TARGETS:
                for mm in MS:
                    k=f"{t}_M{mm}"
                    if k in results:
                        a,r=results[k]; cf.write(f"{t},{mm},True,{a},{r}\n")
        print(f"[DONE] {label} acc={acc} rc={rc}", flush=True)
    return label, acc, rc

def main():
    jobs = [(t,m) for t in TARGETS for m in MS]
    print(f"Launching {len(jobs)} cells, parallel={PARALLEL}, out={OUT}", flush=True)
    with ThreadPoolExecutor(max_workers=PARALLEL) as ex:
        futs = [ex.submit(run_cell,t,m) for t,m in jobs]
        for f in as_completed(futs):
            try: f.result()
            except Exception as e: print("[ERR]",e, flush=True)
    print("ALL DONE", flush=True)
    print(results, flush=True)

if __name__ == "__main__":
    main()
