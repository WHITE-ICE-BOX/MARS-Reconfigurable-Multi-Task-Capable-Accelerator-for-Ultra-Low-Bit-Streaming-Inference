import os
import sys, os, json, torch
REPO=os.environ.get('MARS_TRAIN_ROOT', '.')
sys.path.insert(0,REPO); os.chdir(REPO)
sys.argv=['x','--mode','adapter','--net_bit','1','--dataset','SVHN',
 '--finetune_checkpoint',REPO+'/pretrained_backbones/cifar10_1w1a.tar',
 '--epochs','1','--lr','0.005','--batch_size','100','--num_workers','2','--random_seed','2024',
 '--num_branches','1','--adapter_bit_width','1','--adapter_kernel','1','--adapter_act','signed',
 '--adapter_alpha','scalar','--adapter_mid_basis','in','--no_rc','--adapter_bias']
import bnn_pynq_train_bitwidth as T
args=T.parse_args()
model=T.build_model(args)
ck=torch.load(REPO+'/paper_results_bitwidth/b2_significance/experiments/b2_SVHN_M1_s2024/checkpoints/best.tar',map_location='cpu')
model.load_state_dict(ck.get('state_dict',ck),strict=False)
model=model.cuda().eval()
downs=[(n,m) for n,m in model.named_modules() if 'adapter' in n.lower() and n.endswith('down') and getattr(m,'bias',None) is not None]
names=[n for n,_ in downs]
store={}
def mk(n):
    def h(mod,inp,out):
        t=out[0] if isinstance(out,tuple) else out
        if hasattr(t,'value'): t=t.value
        store[n]=t.detach()
    return h
for n,m in downs: m.register_forward_hook(mk(n))
loaders=T.get_dataloader(args)
test_loader=loaders[1] if isinstance(loaders,(list,tuple)) else loaders
R,B=80.0,160
res={n:{'hist_h':torch.zeros(B),'hist_h0iso':torch.zeros(B),'iso_flips':0,'cum_flips':0,'total':0} for n in names}
nimg=0
with torch.no_grad():
    for x,y in test_loader:
        if nimg>=2000: break
        x=x.cuda()
        model(x); H={n:store[n].clone() for n in names}
        # 單層隔離
        for n,m in downs:
            sv=m.bias.data.clone(); m.bias.data.zero_()
            model(x); h0=store[n].clone()
            m.bias.data.copy_(sv)
            hh,h0f=H[n].float(),h0.float()
            res[n]['iso_flips']+=int(((hh>=0)!=(h0f>=0)).sum())
            res[n]['hist_h']+=torch.histc(hh.flatten().cpu(),bins=B,min=-R,max=R)
            res[n]['hist_h0iso']+=torch.histc(h0f.flatten().cpu(),bins=B,min=-R,max=R)
            res[n]['total']+=hh.numel()
        # 全清零(累積)
        svs={n:m.bias.data.clone() for n,m in downs}
        for n,m in downs: m.bias.data.zero_()
        model(x); H0={n:store[n].clone() for n in names}
        for n,m in downs: m.bias.data.copy_(svs[n])
        for n in names:
            res[n]['cum_flips']+=int(((H[n].float()>=0)!=(H0[n].float()>=0)).sum())
        nimg+=x.size(0)
out={'range':R,'bins':B,'layers':{}}
for n,m in downs:
    out['layers'][n]={'hist_h':res[n]['hist_h'].tolist(),'hist_h0iso':res[n]['hist_h0iso'].tolist(),
        'iso_flip':res[n]['iso_flips']/res[n]['total'],'cum_flip':res[n]['cum_flips']/res[n]['total'],
        'bias':m.bias.data.cpu().flatten().tolist()}
json.dump(out,open('rc_probe_out.json','w'))
for n in names: print(n,'iso=%.4f cum=%.4f'%(out['layers'][n]['iso_flip'],out['layers'][n]['cum_flip']))
print('DONE',nimg)
