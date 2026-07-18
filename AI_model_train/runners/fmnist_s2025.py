#!/usr/bin/env python3
"""Flagship seed-2025 runs: FMNIST->SVHN deployed (Config A) M=1 and M=4, to bound
FMNIST-source seed variance. Same geometry/protocol as fmnist_configA_verify, seed 2025."""
import os, subprocess, threading, re
from concurrent.futures import ThreadPoolExecutor, as_completed
R="/mnt/8tb_hdd/barkie1_hdd/barkie_paper/paper/finn_brevitis/brevitas/src/brevitas_examples/bnn_pynq/claude/repro/claude"
PROJ=os.path.abspath(os.path.join(R,'..'))
PY="/home/esl/anaconda3/envs/claude_repro/bin/python"
TRAIN=os.path.join(R,"bnn_pynq_train_bitwidth.py")
BB=os.path.join(R,"pretrained_backbones","fashionmnist_1w1a.tar")
OUT=os.path.join(R,"paper_results_bitwidth","fashionmnist_configA_verify")  # same dir
EXP=os.path.join(OUT,"experiments"); LOGS=os.path.join(OUT,"logs")
LOCK=threading.Lock(); res={}
def cmd(M):
    n=f"depv_fmnist_SVHN_M{M}_s2025"
    return [PY,'-u',TRAIN,'--mode','adapter','--net_bit','1','--dataset','SVHN',
      '--finetune_checkpoint',BB,'--epochs','200','--lr','0.005','--scheduler','STEP',
      '--milestones','100,150','--batch_size','100','--num_workers','2','--random_seed','2025',
      '--experiments',EXP,'--experiment_name',n,'--num_branches',str(M),'--adapter_bit_width','1',
      '--adapter_kernel','1','--adapter_act','signed','--adapter_alpha','scalar',
      '--adapter_mid_basis','in','--no_rc','--adapter_bias']
def run(M):
    lp=os.path.join(LOGS,f"SVHN_M{M}_s2025.log"); env=os.environ.copy(); env['CUDA_VISIBLE_DEVICES']='1'
    with open(lp,'w') as fp:
        rc=subprocess.Popen(cmd(M),stdout=fp,stderr=subprocess.STDOUT,cwd=PROJ,env=env).wait()
    acc=None
    try:
        m=re.findall(r'Final Best Accuracy:\s*([0-9.]+)%',open(lp).read())
        if m: acc=float(m[-1])
    except: pass
    with LOCK:
        res[M]=(acc,rc)
        with open(os.path.join(OUT,'s2025.csv'),'w') as f:
            f.write("target,M,seed,acc\n")
            for mm in sorted(res): f.write(f"SVHN,{mm},2025,{res[mm][0]}\n")
        print(f"[DONE] SVHN M{M} s2025 acc={acc}",flush=True)
with ThreadPoolExecutor(max_workers=2) as ex:
    fs=[ex.submit(run,M) for M in [1,4]]
    for f in as_completed(fs):
        try: f.result()
        except Exception as e: print("[ERR]",e,flush=True)
print("S2025_DONE",res,flush=True)
