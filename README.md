# 黃柏鈞 碩士論文交接包

> **MARS: A Reconfigurable Accelerator Architecture with Runtime Task Switching for Ultra-Low-Bit Streaming Inference**
> （MARS = Multi-Branch Adapter Reconfigurable Streaming-accelerator）
> 國立中正大學 · 碩士論文最終版 · 完整交接資料

## 資料夾

| 資料夾 | 內容 |
|---|---|
| [`01_論文全文/`](01_論文全文/) | 論文 LaTeX 原始碼（`merged.tex`）、所需圖檔、中英文定稿 PDF |
| [`02_圖片原始檔/`](02_圖片原始檔/) | 論文每張圖的編輯檔（依章分 ch3/ch4/ch5）:python 繪圖腳本已附;架構示意圖 pptx 見各章 README |
| [`03_期刊論文/`](03_期刊論文/) | IEEEtran journal 版（11 頁）tex + PDF + 書目 |
| [`04_會議論文/`](04_會議論文/) | IEEEtran conference 版（5 頁）tex + PDF |
| [`05_程式碼/`](05_程式碼/) | 完整程式碼與數據:訓練、FINN 合成、RTL、SoC、FPGA 部署、合成掃描、跨平台量測、繪圖分析（詳見其 README 與論文對應表） |
| [`06_資料集/`](06_資料集/) | 五個公開資料集之來源、版本與取得說明 |
| [`07_碩士口試/`](07_碩士口試/) | 口試簡報 pptx |

## 快速指引

- **看論文**:`01_論文全文/*.pdf`
- **重現實驗/圖表**:`05_程式碼/README.md` 的〈論文對應表〉與〈重現指南〉（環境版本、逐步驟）
- **改圖**:`02_圖片原始檔/`（python 圖腳本已附;架構圖 pptx 見各章 README）
- **投稿**:`03_期刊論文/`、`04_會議論文/`

## 論文一句話

MARS 把 Conv-Adapter 整合進凍結的 1W1A FINN streaming-dataflow backbone,以 19-LUT 的
Function Switch Controller 做單一 bitstream 執行時期任務切換;多分支 Adapter 於超低位元下
恢復遷移準確率,Residual Correction 於 1-bit 顯著。平台 PYNQ-Z2（XC7Z020）。

## 引用
> Po-Chun Huang, "MARS: A Reconfigurable Accelerator Architecture with Runtime Task Switching for Ultra-Low-Bit Streaming Inference," Master's Thesis, National Chung Cheng University, 2026.
