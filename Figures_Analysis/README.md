# Figures_Analysis — 資料驅動圖表與分析腳本

| 檔案 | 對應論文 | 說明 |
|---|---|---|
| `rc_probe_fig5_2.py` | Fig 5.2 資料來源 | 於 GPU 主機載入部署幾何 M=1 checkpoint（`b2_SVHN_M1_s2024/best.tar`），對 2,000 張 SVHN 測試影像做「含/去 RC」雙前向：單層隔離與全移除兩種模式，輸出各層前激活直方圖、學得偏置、符號翻轉率 → `rc_probe_out.json`。路徑常數 `REPO` 需改成你的訓練程式目錄。 |
| `rc_probe_out.json` | Fig 5.2 數據 | 上述輸出（論文使用之原始數據）。 |
| `plot_rc_mechanism_fig5_2.py` | Fig 5.2 | 讀 `rc_probe_out.json` 繪三面板圖（偏置箱型／A1 前激活 vs 符號切點／翻轉率 iso+cascade）。 |
| `plot_fig5_4_5_5_tradeoff_power.py` | Fig 5.4 / 5.5 | 多分支準確率增益對合成後 LUT／總功耗曲線（大增幅 Δmulti≥3pp 九對、小增幅十一對、全 20 對平均；資料內嵌自 `Synth_Sweep` 彙整與 20 對掃描）。 |
| `parse_lastepoch_b2.py` | §5.2.5 交叉檢核 | 從 b2 訓練 log 解析最終 epoch（無 checkpoint 選擇）test 準確率，重算配對 M=4−M=1 增益（SVHN +6.87±0.50 / FashionMNIST +2.99±0.40），驗證相對增益非 best-epoch 選點假象。 |

量測翻轉率參考值（2,000 張，seed 2024）：單層隔離 A1–A5 = 4.9/1.3/2.5/1.2/1.4%；全移除連鎖 = 4.9/2.7/15.2/14.7/14.0%。
