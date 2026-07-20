# 02_圖片原始檔 — 論文每張圖的編輯檔

依論文章節分 `ch3/ch4/ch5`。分兩類:

- **python 繪製（資料驅動圖,編輯檔已附）**:改腳本重跑即重生。
- **PPT 架構示意圖**:原始 `.pptx` 放入對應章節資料夾,檔名依論文正文圖號（本 release 論文用之 PNG 成品見 `01_論文全文/figures/`）。

## 逐圖對應

編號依論文正文實際圖號。

| Fig | 檔名 | 編輯檔 | 位置 |
|---|---|---|---|
| 3.1 | sw_network | `fig3.1_sw_network.pptx` | ch3/ ✓ |
| 3.2 | sw_single_adapter | `fig3.2_sw_single_adapter.pptx` | ch3/ ✓ |
| 3.3 | sw_multiadapter | `fig3.3_sw_multiadapter.pptx` | ch3/ ✓ |
| 4.1 | mars_soc（fig42_mars_soc）| `fig4.1_mars_soc.pptx` | ch4/ ✓ |
| 4.2 | hw_finn_singletask_npu | `fig4.2_hw_finn_singletask_npu.pptx` | ch4/ ✓ |
| 4.3 | mars_arch（fig44_mars_arch）| `fig4.3_mars_arch.pptx` | ch4/ ✓ |
| 4.4 | hw_finn_mvau_wrapper | `fig4.4_hw_finn_mvau_wrapper.pptx` | ch4/ ✓ |
| 4.5 | hw_super_wrapper | `fig4.5_hw_super_wrapper.pptx` | ch4/ ✓ |
| 4.6 | hw_adapter_internal | `fig4.6_hw_adapter_internal.pptx` | ch4/ ✓ |
| 4.7 | rc_in_hardware | `fig4.7_rc_in_hardware.pptx` | ch4/ ✓ |
| 4.8 | cfg_hub 系統整合圖 | TikZ 內嵌（tex 原始碼） | — |
| 4.9 | fsc_circuit | `fig4.9_fsc_circuit.pptx` | ch4/ ✓ |
| 4.10 | cfg_hub 64KB 位址映射 | TikZ 內嵌（tex 原始碼） | — |
| 4.11 | task_switch | `fig4.11_task_switch.pptx` | ch4/ ✓ |
| 5.1 | hw_end2end | `fig5.1_hw_end2end.pptx` | ch5/ ✓ |
| 5.2 | rc_mechanism | `rc_probe_fig5_2.py` + `plot_rc_mechanism_fig5_2.py` + `rc_probe_out.json` | ch5/ ✓ |
| 5.3 | mars_soc_layout | Vivado implemented design 截圖（非 pptx,由 Vivado GUI 匯出） | ch5/ |
| 5.4 | pe_diff | `fig5.4_pe_diff.pptx` | ch5/ ✓ |
| 5.5/5.6 | mb_tradeoff_*（4圖） | `plot_fig5_4_5_5.py` | ch5/ ✓ |

TikZ 內嵌圖（Fig 4.8 cfg_hub 系統圖、Fig 4.10 address map、跨平台能效圖）之編輯檔即論文
`01_論文全文/MARS_碩士論文.tex`（THESIS 端為 `merged.tex`）原始碼。
