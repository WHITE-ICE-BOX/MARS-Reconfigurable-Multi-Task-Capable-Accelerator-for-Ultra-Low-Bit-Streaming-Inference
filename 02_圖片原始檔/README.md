# 02_圖片原始檔 — 論文每張圖的編輯檔

依論文章節分 `ch3/ch4/ch5`。分兩類:

- **python 繪製（資料驅動圖,編輯檔已附）**:改腳本重跑即重生。
- **PPT 架構示意圖**:原始 `.pptx` 由作者提供放入對應章節資料夾（本 release 論文用之 PNG 成品見 `01_論文全文/`）。

## 逐圖對應

| Fig | 檔名 | 編輯檔 | 位置 |
|---|---|---|---|
| 3.1 | sw_network | **pptx（待放）** | ch3/ |
| 3.2 | sw_single_adapter | **pptx（待放）** | ch3/ |
| 3.3 | sw_multiadapter | **pptx（待放）** | ch3/ |
| 4.1 | fig42_mars_soc | **pptx（待放）** | ch4/ |
| 4.2 | hw_finn_singletask_npu | **pptx（待放）** | ch4/ |
| 4.3 | fig44_mars_arch | **pptx（待放）** | ch4/ |
| 4.4 | hw_finn_mvau_wrapper | **pptx（待放）** | ch4/ |
| 4.5 | hw_super_wrapper | **pptx（待放）** | ch4/ |
| 4.6 | hw_adapter_internal | **pptx（待放）** | ch4/ |
| 4.7 | rc_in_hardware | **pptx（待放）** | ch4/ |
| 4.8 | fsc_circuit | **pptx（待放）** | ch4/ |
| 4.9 | task_switch | **pptx（待放）** | ch4/ |
| 5.1 | hw_end2end | **pptx（待放）** | ch5/ |
| 5.2 | rc_mechanism | `rc_probe_fig5_2.py` + `plot_rc_mechanism_fig5_2.py` + `rc_probe_out.json` | ch5/ ✓ |
| 5.3 | mars_soc_layout | Vivado implemented design 截圖（非 pptx,由 Vivado GUI 匯出） | ch5/ |
| 5.4 | pe_diff | **pptx（待放）** | ch5/ |
| 5.5/5.6 | mb_tradeoff_*（4圖） | `plot_fig5_4_5_5.py` | ch5/ ✓ |

TikZ 內嵌圖（cfg_hub 系統圖、address map、跨平台能效圖）之編輯檔即論文 `01_論文全文/merged.tex` 原始碼。
