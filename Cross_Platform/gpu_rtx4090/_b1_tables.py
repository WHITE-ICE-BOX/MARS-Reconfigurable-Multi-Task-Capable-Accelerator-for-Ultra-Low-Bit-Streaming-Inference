import os
import sys, time, threading, configparser, statistics as S
CLAUDE=os.environ.get("CLAUDE_SRC", ".")
sys.path.insert(0, CLAUDE+"/cross_platform_bench"); sys.path.insert(0, CLAUDE)
import torch, pynvml
import benchmark_svhn as B
from models_bitwidth.CNV_param import cnv_param
torch.cuda.set_device(1)
pynvml.nvmlInit(); H=pynvml.nvmlDeviceGetHandleByIndex(1)
def pmon(ev,out):
    rs=[]
    while not ev.is_set():
        try: rs.append(pynvml.nvmlDeviceGetPowerUsage(H)/1000.0)
        except: pass
        time.sleep(0.05)
    out['avg']=sum(rs)/len(rs) if rs else 0
def k3cfg():
    c=configparser.ConfigParser()
    c.add_section('QUANT');[c.set('QUANT',k,v) for k,v in[('WEIGHT_BIT_WIDTH','1'),('ACT_BIT_WIDTH','1'),('IN_BIT_WIDTH','8')]]
    c.add_section('MODEL');[c.set('MODEL',k,v) for k,v in[('NUM_CLASSES','10'),('IN_CHANNELS','3')]]
    c.add_section('ADAPTER');[c.set('ADAPTER',k,v) for k,v in[('NUM_BRANCHES','1'),('BIT_WIDTH','1'),('RC_BIT_WIDTH','8'),('USE_RC','False'),('KERNEL_SIZE','3'),('ACT_MODE','relu'),('ALPHA_MODE','per_channel'),('USE_BIAS','False'),('MID_BASIS','out')]]
    return c
_,loader=B.build_svhn_loader(batch_size=1000,num_workers=2)
def run(model,name,ops):
    model=model.cuda().eval()
    w=torch.randn(1000,3,32,32,device='cuda')
    with torch.no_grad():
        for _ in range(30): model(w)
    torch.cuda.synchronize()
    fl=[];pl=[]
    for _ in range(5):
        ev=threading.Event();out={};th=threading.Thread(target=pmon,args=(ev,out));th.start()
        seen=0;t0=time.time()
        with torch.no_grad():
            for x,_ in loader:
                model(x.cuda(non_blocking=True));torch.cuda.synchronize();seen+=x.size(0)
                if seen>=10000:break
        dt=time.time()-t0;ev.set();th.join();fl.append(seen/dt);pl.append(out['avg'])
    fps=S.mean(fl);pw=S.mean(pl)
    print(f"{name:22s} fps={fps:8.1f} power={pw:6.2f}W GOPS={fps*ops:7.1f} eff={fps/pw:6.2f} img/s/W",flush=True)
run(B.cnv(B.create_mock_config(use_adapter=False)),'backbone (Tab5.14)',0.11892)
run(cnv_param(k3cfg()),'ConvAdapter-k3 (Tab5.15)',0.15161)
print("DONE_B1T")
