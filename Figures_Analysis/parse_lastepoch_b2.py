#!/usr/bin/env python3
"""論文 §5.2.5 之「無選擇 last-epoch 交叉檢核」解析器。
從 b2_significance 各 run 的 log.txt 讀取最終 epoch(第 200 個)之 test 準確率
(最後一個 `Test: [..]` 行之累計 Prec@1),與 best-epoch 協定對照:
  last-epoch 配對增益 SVHN +6.87±0.50 / FashionMNIST +2.99±0.40
  (best-epoch 為 +6.64±0.43 / +2.69±0.36;選點僅膨脹絕對值 0.5–0.8pp)
用法: python3 parse_lastepoch_b2.py <b2_significance/experiments 目錄>
"""
import sys, re, statistics as st, pathlib
root=pathlib.Path(sys.argv[1] if len(sys.argv)>1 else 'experiments')
res={}
for ds in ['SVHN','FashionMNIST']:
    for m in (1,4):
        for seed in range(2024,2029):
            log=root/f'b2_{ds}_M{m}_s{seed}'/'log.txt'
            last=None
            for line in open(log,errors='ignore'):
                if 'Test: [' in line:
                    mm=re.search(r'Prec@1 [0-9.]+ \(([0-9.]+)\)',line)
                    if mm: last=float(mm.group(1))
            res[(ds,m,seed)]=last
for ds in ['SVHN','FashionMNIST']:
    diffs=[res[(ds,4,s)]-res[(ds,1,s)] for s in range(2024,2029)]
    print(f'{ds}: last-epoch paired M4-M1 = {st.mean(diffs):+.2f} ± {st.stdev(diffs):.2f} pp '
          f'({["%.2f"%d for d in diffs]})')
