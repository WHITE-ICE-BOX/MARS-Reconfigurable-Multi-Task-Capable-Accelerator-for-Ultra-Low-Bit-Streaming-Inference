import os
import sys,time,threading,configparser,statistics as S,subprocess
CLAUDE=os.environ.get("CLAUDE_SRC", ".")
sys.path.insert(0,CLAUDE+"/cross_platform_bench");sys.path.insert(0,CLAUDE)
import torch,pynvml
import benchmark_svhn as B
from models_bitwidth.CNV_param import cnv_param
pynvml.nvmlInit();H=pynvml.nvmlDeviceGetHandleByIndex(1)
def gpu1_busy():
    u=pynvml.nvmlDeviceGetUtilizationRates(H).gpu
    m=pynvml.nvmlDeviceGetMemoryInfo(H).used/1e6
    return u>5 or m>1500
# wait for idle window (up to 6h)
waited=0
while gpu1_busy() and waited<21600:
    time.sleep(120);waited+=120
if gpu1_busy():
    print("NEVER_IDLE (gpu1 busy 6h)");sys.exit()
print(f"GPU1 idle after {waited}s, measuring...",flush=True)
torch.cuda.set_device(1)
def pmon(ev,o):
    rs=[]
    while not ev.is_set():
        try:rs.append(pynvml.nvmlDeviceGetPowerUsage(H)/1000.0)
        except:pass
        time.sleep(0.05)
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
    torch.cuda.synchronize();fl=[];pl=[];busy=False
    for _ in range(5):
        if gpu1_busy():busy=True
        ev=threading.Event();o={};th=threading.Thread(target=pmon,args=(ev,o));th.start()
        seen=0;t0=time.time()
        with torch.no_grad():
            for x,_ in loader:
                m(x.cuda(non_blocking=True));torch.cuda.synchronize();seen+=x.size(0)
                if seen>=10000:break
        dt=time.time()-t0;ev.set();th.join();fl.append(seen/dt);pl.append(o['avg'])
    fps=S.mean(fl);pw=S.mean(pl)
    flag=" (CONTAMINATED mid-run!)" if busy else ""
    print(f"{name:22s} fps={fps:8.1f} power={pw:6.2f}W GOPS={fps*ops:7.1f} eff={fps/pw:6.2f}{flag}",flush=True)
run(B.cnv(B.create_mock_config(use_adapter=False)),'backbone(Tab5.14)',0.11892)
run(cnv_param(k3cfg()),'ConvAdapter-k3(Tab5.15)',0.15161)
print("DONE_B1AUTO")
