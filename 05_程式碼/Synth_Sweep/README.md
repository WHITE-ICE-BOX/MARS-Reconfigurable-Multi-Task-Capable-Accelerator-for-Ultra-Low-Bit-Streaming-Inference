# Synth_Sweep — 多分支 M=1–4 合成掃描（論文 Tables 5.15–5.17、Figs 5.4–5.5）

兩種 build（compactness PE=1 / throughput 異質 PE）各自把 M=1 的 Super Wrapper 複製成 M=2–4 平行分支變體，走與部署完全相同的 FINN Zynq 合成流程，於 synthesis 階段報告資源與 vectorless 功耗（M≥2 超出 XC7Z020，未 place-and-route、未上板）。

| 內容 | 位置 |
|---|---|
| M 分支 RTL 產生器 | `scripts/gen_multibranch_rtl.py`（由 M=1 RTL 生成 M=2–4 變體） |
| Golden/模擬產生 | `scripts/gen_multibranch_golden.py`、`gen_multibranch_sims.py`（逐 MVAU RTL 模擬 40/40 bit-exact） |
| Vivado 流程 | `scripts/gen_zynq_tcl.py`、`synth_global_report.tcl`、`repackage_ips.tcl` 等 |
| 結果彙整 | `scripts/collect_tables.py` → 論文 Tables 5.15–5.17 數值 |
| 繪圖 | `../Figures_Analysis/plot_fig5_4_5_5_tradeoff_power.py` |
| M=2–4 RTL 變體 | `rtl_multibranch/`（compact 與 tp 兩系列） |
| Vivado 報告存檔 | `results_archive/`（各 M、各 build 之 utilization / power 報告） |
