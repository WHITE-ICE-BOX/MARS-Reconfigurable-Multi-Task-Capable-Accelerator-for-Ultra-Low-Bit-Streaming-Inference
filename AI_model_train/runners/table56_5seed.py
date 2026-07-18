import sys
#!/usr/bin/env python3
"""Table 5.6 (tab:multiseed) as a genuine 5-seed, same-host (A6000) experiment.
Two configs x 5 seeds on CIFAR-10->SVHN 1W1A:
  full_ft   : mode full_ft, net_bit 1 (upper bound)
  mars_m4   : deployed MARS M=4 + RC (kernel1/signed/scalar/mid=in, --adapter_bias)
"""
import os, subprocess, threading, re
from concurrent.futures import ThreadPoolExecutor, as_completed
R=os.environ.get("MARS_TRAIN_ROOT", ".")
PROJ=os.path.abspath(os.path.join(R,'..'))
PYEXE=sys.executable
TRAIN=os.path.join(R,"bnn_pynq_train_bitwidth.py")
BB=os.path.join(R,"pretrained_backbones","cifar10_1w1a.tar")
OUT=os.path.join(R,"paper_results_bitwidth","table56_5seed")
EXP=os.path.join(OUT,"experiments"); LOGS=os.path.join(OUT,"logs")
os.makedirs(EXP,exist_ok=True); os.makedirs(LOGS,exist_ok=True)
SEEDS=[2024,2025,2026,2027,2028]; EP=200; MIL="100,150"
LOCK=threading.Lock(); res={}
def base(name,sd):
    return [PYEXE,'-u',TRAIN,'--net_bit','1','--dataset','SVHN','--finetune_checkpoint',BB,
      '--epochs',str(EP),'--lr','0.005','--scheduler','STEP','--milestones',MIL,
      '--batch_size','100','--num_workers','2','--random_seed',str(sd),
      '--experiments',EXP,'--experiment_name',name]
def cmd(cfg,sd):
    name=f"t56_{cfg}_s{sd}"
    if cfg=="full_ft":
        return name,base(name,sd)+['--mode','full_ft']
    else:  # mars_m4 deployed
        return name,base(name,sd)+['--mode','adapter','--num_branches','4','--adapter_bit_width','1',
          '--adapter_kernel','1','--adapter_act','signed','--adapter_alpha','scalar',
          '--adapter_mid_basis','in','--no_rc','--adapter_bias']
def run(cfg,sd):
    name,cc=cmd(cfg,sd); lp=os.path.join(LOGS,f"{name}.log"); env=os.environ.copy(); env['CUDA_VISIBLE_DEVICES']='1'
    with open(lp,'w') as fp:
        rc=subprocess.Popen(cc,stdout=fp,stderr=subprocess.STDOUT,cwd=PROJ,env=env).wait()
    acc=None
    try:
        m=re.findall(r'Final Best Accuracy:\s*([0-9.]+)%',open(lp).read())
        if m: acc=float(m[-1])
    except: pass
    with LOCK:
        res[(cfg,sd)]=(acc,rc)
        with open(os.path.join(OUT,'table56.csv'),'w') as f:
            f.write("config,seed,acc,rc\n")
            for cf in ["full_ft","mars_m4"]:
                for s in SEEDS:
                    if (cf,s) in res: a,r=res[(cf,s)]; f.write(f"{cf},{s},{a},{r}\n")
        print(f"[DONE] {cfg} s{sd} acc={acc} rc={rc}",flush=True)
jobs=[(cf,s) for cf in ["full_ft","mars_m4"] for s in SEEDS]
print(f"launching {len(jobs)} cells parallel10 on A6000",flush=True)
with ThreadPoolExecutor(max_workers=10) as ex:
    fs=[ex.submit(run,cf,s) for cf,s in jobs]
    for f in as_completed(fs):
        try: f.result()
        except Exception as e: print("[ERR]",e,flush=True)
print("TABLE56_DONE",res,flush=True)
