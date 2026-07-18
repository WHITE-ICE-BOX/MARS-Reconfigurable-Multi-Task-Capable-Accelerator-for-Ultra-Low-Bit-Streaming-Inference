#!/usr/bin/env python3
"""論文 Figure 5.2 (RC mechanism-level probe) 繪圖器。
輸入: rc_probe_out.json (由 rc_probe_fig5_2.py 於 GPU 主機產生)
輸出: rc_mechanism.png — 三面板:
  (a) 各 adapter 層學得之逐通道 RC 偏置(箱型圖)
  (b) Adapter 1 前激活分佈 vs 符號切點(含/去 RC,2 單位 bin 避免二值格點疊頻)
  (c) 移除 RC 之二值隱藏激活翻轉率(單層隔離 vs 全移除連鎖)
"""
import json, numpy as np
import matplotlib; matplotlib.use('Agg')
import matplotlib.pyplot as plt
plt.rcParams.update({'font.family':'STIXGeneral','mathtext.fontset':'stix','font.size':11})
d=json.load(open('rc_probe_out.json'))
R,B=d['range'],d['bins']
names=[f'adapters.{i}.down' for i in range(1,6)]
bias={i:np.array(d['layers'][f'adapters.{i}.down']['bias']) for i in range(1,6)}
fig,axes=plt.subplots(1,3,figsize=(13,3.6))
ax=axes[0]
ax.boxplot([bias[i] for i in range(1,6)],tick_labels=[f'A{i}' for i in range(1,6)],showfliers=True,widths=0.5)
ax.axhline(0,color='0.6',lw=0.8,ls='--')
ax.set_xlabel('Adapter layer'); ax.set_ylabel('Learned RC bias (latent value)')
ax.set_title('(a) Learned per-channel RC biases',fontsize=11)
L='adapters.1.down'
h=np.array(d['layers'][L]['hist_h']); h0=np.array(d['layers'][L]['hist_h0iso'])
h2=h.reshape(-1,2).sum(1); h02=h0.reshape(-1,2).sum(1)
edges=np.linspace(-R,R,B//2+1); ctr=(edges[:-1]+edges[1:])/2
ax=axes[1]
ax.step(ctr,h02/h02.sum(),where='mid',color='#c0392b',lw=1.6,label='RC removed ($h-b$)')
ax.step(ctr,h2/h2.sum(),where='mid',color='#1a7a3a',lw=1.6,label='with RC ($h$)')
ax.axvline(0,color='k',lw=1.0)
ax.set_xlim(-25,25); ax.set_xlabel('Adapter 1 pre-activation'); ax.set_ylabel('Density')
ax.set_title('(b) Pre-activation distribution vs. sign cut',fontsize=11)
ax.legend(fontsize=9,frameon=True,loc='upper left',framealpha=0.9,edgecolor='0.8')
ax=axes[2]
iso=[d['layers'][n]['iso_flip']*100 for n in names]
cum=[d['layers'][n]['cum_flip']*100 for n in names]
xx=np.arange(5); w=0.38
b1=ax.bar(xx-w/2,iso,w,color='#3a63a8',label='own-layer bias only')
b2=ax.bar(xx+w/2,cum,w,color='#e08a2e',label='all RC removed (cascade)')
for b,v in list(zip(b1,iso))+list(zip(b2,cum)):
    ax.text(b.get_x()+b.get_width()/2,v+0.3,f'{v:.1f}',ha='center',fontsize=8)
ax.set_xticks(xx); ax.set_xticklabels([f'A{i}' for i in range(1,6)])
ax.set_ylabel('Binary hidden activations flipped (%)'); ax.set_xlabel('Adapter layer')
ax.set_ylim(0,18); ax.legend(fontsize=9,frameon=False)
ax.set_title('(c) Sign flips from removing RC (2,000 images)',fontsize=11)
plt.tight_layout(); plt.savefig('rc_mechanism.png',dpi=200,facecolor='white')
print('saved rc_mechanism.png')
