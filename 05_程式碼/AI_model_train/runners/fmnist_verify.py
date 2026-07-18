import sys
#!/usr/bin/env python3
"""Verification run: FMNIST-source 1-bit configC SVHN M1-4, 50 epochs, to check if the
old SVHN column (M3=M4=45.68223724646589 duplicate) is a real bug. Same geometry as
run_configC_cross.build_adapter (kernel3/relu/per-ch/mid=out, RC=--adapter_bias)."""
import os, subprocess, threading, re
from concurrent.futures import ThreadPoolExecutor, as_completed
R=os.environ.get("MARS_TRAIN_ROOT", ".")
PROJ=os.path.abspath(os.path.join(R,'..'))
PY=sys.executable
TRAIN=os.path.join(R,"bnn_pynq_train_bitwidth.py")
BB=os.path.join(R,"pretrained_backbones","fashionmnist_1w1a.tar")
OUT=os.path.join(R,"paper_results_bitwidth","fashionmnist_configC_SVHN_verify")
EXP=os.path.join(OUT,"experiments"); LOGS=os.path.join(OUT,"logs")
os.makedirs(EXP,exist_ok=True); os.makedirs(LOGS,exist_ok=True)
EP=50; MIL=f"{int(EP*0.5)},{int(EP*0.75)}"
LOCK=threading.Lock(); res={}
def cmd(M):
    n=f"Transfer_fmnist2oCC_SVHN_M{M}_rc_e{EP}_verify"
    return [PY,'-u',TRAIN,'--mode','adapter','--net_bit','1','--dataset','SVHN',
      '--finetune_checkpoint',BB,'--epochs',str(EP),'--lr','0.005','--scheduler','STEP',
      '--milestones',MIL,'--batch_size','100','--num_workers','2','--random_seed','2024',
      '--experiments',EXP,'--experiment_name',n,'--num_branches',str(M),'--adapter_bit_width','1',
      '--adapter_kernel','3','--adapter_act','relu','--adapter_alpha','per_channel',
      '--adapter_mid_basis','out','--no_rc','--adapter_bias']
def run(M):
    lp=os.path.join(LOGS,f"SVHN_M{M}.log"); env=os.environ.copy(); env['CUDA_VISIBLE_DEVICES']='1'
    with open(lp,'w') as fp:
        rc=subprocess.Popen(cmd(M),stdout=fp,stderr=subprocess.STDOUT,cwd=PROJ,env=env).wait()
    acc=None
    try:
        m=re.findall(r'Final Best Accuracy:\s*([0-9.]+)%',open(lp).read())
        if m: acc=float(m[-1])
    except: pass
    with LOCK:
        res[M]=(acc,rc)
        with open(os.path.join(OUT,'verify.csv'),'w') as f:
            f.write("dataset,M,acc,rc\n")
            for mm in sorted(res): f.write(f"SVHN,{mm},{res[mm][0]},{res[mm][1]}\n")
        print(f"[DONE] SVHN M{M} acc={acc} rc={rc}",flush=True)
print(f"verify SVHN M1-4 @ {EP}ep, out={OUT}",flush=True)
with ThreadPoolExecutor(max_workers=4) as ex:
    fs=[ex.submit(run,M) for M in [1,2,3,4]]
    for f in as_completed(fs):
        try: f.result()
        except Exception as e: print("[ERR]",e,flush=True)
print("VERIFY_DONE",res,flush=True)
