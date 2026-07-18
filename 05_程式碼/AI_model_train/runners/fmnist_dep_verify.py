import sys
#!/usr/bin/env python3
"""Independent retrain of deployed (Config A) FMNIST-source cells for Table 5.17 verification.
kernel1/signed/scalar/mid=in + RC (--adapter_bias), 1-bit, 200ep, seed 2024. 4 targets x M1-4 = 16 cells."""
import os, subprocess, threading, re
from concurrent.futures import ThreadPoolExecutor, as_completed
R=os.environ.get("MARS_TRAIN_ROOT", ".")
PROJ=os.path.abspath(os.path.join(R,'..'))
PY=sys.executable
TRAIN=os.path.join(R,"bnn_pynq_train_bitwidth.py")
BB=os.path.join(R,"pretrained_backbones","fashionmnist_1w1a.tar")
OUT=os.path.join(R,"paper_results_bitwidth","fashionmnist_configA_verify")
EXP=os.path.join(OUT,"experiments"); LOGS=os.path.join(OUT,"logs")
os.makedirs(EXP,exist_ok=True); os.makedirs(LOGS,exist_ok=True)
TARGETS=["SVHN","CIFAR10","STL10","CINIC10"]; MS=[1,2,3,4]
LOCK=threading.Lock(); res={}
def cmd(t,M):
    n=f"depv_fmnist_{t}_M{M}"
    return [PY,'-u',TRAIN,'--mode','adapter','--net_bit','1','--dataset',t,
      '--finetune_checkpoint',BB,'--epochs','200','--lr','0.005','--scheduler','STEP',
      '--milestones','100,150','--batch_size','100','--num_workers','2','--random_seed','2024',
      '--experiments',EXP,'--experiment_name',n,'--num_branches',str(M),'--adapter_bit_width','1',
      '--adapter_kernel','1','--adapter_act','signed','--adapter_alpha','scalar',
      '--adapter_mid_basis','in','--no_rc','--adapter_bias']
def run(t,M):
    lp=os.path.join(LOGS,f"{t}_M{M}.log"); env=os.environ.copy(); env['CUDA_VISIBLE_DEVICES']='1'
    with open(lp,'w') as fp:
        rc=subprocess.Popen(cmd(t,M),stdout=fp,stderr=subprocess.STDOUT,cwd=PROJ,env=env).wait()
    acc=None
    try:
        m=re.findall(r'Final Best Accuracy:\s*([0-9.]+)%',open(lp).read())
        if m: acc=float(m[-1])
    except: pass
    with LOCK:
        res[(t,M)]=(acc,rc)
        with open(os.path.join(OUT,'verify.csv'),'w') as f:
            f.write("target,M,acc,rc\n")
            for tt in TARGETS:
                for mm in MS:
                    if (tt,mm) in res: a,r=res[(tt,mm)]; f.write(f"{tt},{mm},{a},{r}\n")
        print(f"[DONE] {t} M{M} acc={acc}",flush=True)
jobs=[(t,m) for t in TARGETS for m in MS]
print(f"launching {len(jobs)} cells parallel8",flush=True)
with ThreadPoolExecutor(max_workers=8) as ex:
    fs=[ex.submit(run,t,m) for t,m in jobs]
    for f in as_completed(fs):
        try: f.result()
        except Exception as e: print("[ERR]",e,flush=True)
print("DEPV_DONE",res,flush=True)
