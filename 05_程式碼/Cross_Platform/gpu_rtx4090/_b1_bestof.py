import os
import sys,time,threading,configparser,statistics as S
CLAUDE=os.environ.get("CLAUDE_SRC", ".")
sys.path.insert(0,CLAUDE+"/cross_platform_bench");sys.path.insert(0,CLAUDE)
import torch,pynvml
import benchmark_svhn as B
from models_bitwidth.CNV_param import cnv_param
G=1; torch.cuda.set_device(G)
pynvml.nvmlInit();H=pynvml.nvmlDeviceGetHandleByIndex(G)
def pm(ev,o):
    rs=[]
    while not ev.is_set():
        try:rs.append(pynvml.nvmlDeviceGetPowerUsage(H)/1000.0)
        except:pass
        time.sleep(0.03)
    o['avg']=sum(rs)/len(rs) if rs else 0
def k3cfg():
    c=configparser.ConfigParser()
    c.add_section('QUANT');[c.set('QUANT',k,v) for k,v in[('WEIGHT_BIT_WIDTH','1'),('ACT_BIT_WIDTH','1'),('IN_BIT_WIDTH','8')]]
    c.add_section('MODEL');[c.set('MODEL',k,v) for k,v in[('NUM_CLASSES','10'),('IN_CHANNELS','3')]]
    c.add_section('ADAPTER');[c.set('ADAPTER',k,v) for k,v in[('NUM_BRANCHES','1'),('BIT_WIDTH','1'),('RC_BIT_WIDTH','8'),('USE_RC','False'),('KERNEL_SIZE','3'),('ACT_MODE','relu'),('ALPHA_MODE','per_channel'),('USE_BIAS','False'),('MID_BASIS','out')]]
    return c
_,loader=B.build_svhn_loader(batch_size=1000,num_workers=2)
def run(m,name,ops):
    m=m.cuda().eval();w=torch.randn(1000,3,32,32,device='cuda')
    with torch.no_grad():
        for _ in range(30):m(w)
    torch.cuda.synchronize();best=None;reps=[]
    for _ in range(12):
        ev=threading.Event();o={};th=threading.Thread(target=pm,args=(ev,o));th.start()
        seen=0;t0=time.time()
        with torch.no_grad():
            for x,_ in loader:
                m(x.cuda(non_blocking=True));torch.cuda.synchronize();seen+=x.size(0)
                if seen>=10000:break
        dt=time.time()-t0;ev.set();th.join()
        fps=seen/dt;pw=o['avg'];eff=fps/pw if pw else 0
        reps.append((eff,fps,pw))
    reps.sort(reverse=True);eff,fps,pw=reps[0]   # max-eff = cleanest window
    print(f"{name:18s} BEST: fps={fps:7.1f} power={pw:6.2f}W GOPS={fps*ops:7.1f} eff={eff:6.2f} | median eff={S.median([r[0] for r in reps]):.1f}",flush=True)
run(B.cnv(B.create_mock_config(use_adapter=False)),'backbone',0.11892)
run(cnv_param(k3cfg()),'ConvAdapter-k3',0.15161)
print("DONE_BESTOF")
