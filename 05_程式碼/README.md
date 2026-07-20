# MARS — 具多任務能力之超低位元串流推論可重組加速器架構

> **MARS: A Reconfigurable Multi-Task-Capable Accelerator Architecture for Ultra-Low-Bit Streaming Inference**
> （MARS = **M**ulti-Branch **A**dapter **R**econfigurable **S**treaming-accelerator）
> 碩士論文最終版程式碼與數據釋出。論文中每一項實驗與資料驅動圖表的對應程式碼見〈八、論文對應表〉。

---

## 一、這個專案在做什麼

MARS 把 **Conv-Adapter**（參數高效率遷移學習模組）整合進一個**凍結的 1W1A**（1-bit weight / 1-bit activation）**FINN streaming-dataflow CNV backbone**，並加入一個 AXI-Lite 的 **Function Switch Controller（`cfg_hub`）** 做**執行時期任務切換（runtime task switching）**。

核心貢獻（與論文定稿口徑一致）：
1. **硬體整合**——自研 Adapter RTL 以「Super Wrapper」方式包進 FINN 產生的 MVAU（Matrix-Vector-Activation Unit）串流資料流，週期精準（cycle-accurate）同步；不用 DSP、不增加 BRAM tile（adapter 狀態全在分散式 RAM）。
2. **單一 bitstream 執行時期任務切換**——`cfg_hub`（19 LUT）讓**一顆 bitstream** 在不做 fabric reconfiguration 下，服務**合格任務**（同凍結 backbone、32×32×3 輸入、同 10 類輸出 head、分類任務）：晶片成本對任務數為 O(1)、主機端組態影像隨任務數 O(T) 成長；切換＝寫入一份 25,088 bytes 的任務參數（6,757 個 32-bit 寫入 = 27,028 bus bytes），組態重寫約 1.86±0.04 ms（切換後推論正確性另行驗證）。板上以**五份 host 常駐任務影像**展示（FPGA 上僅保存一組 active 任務狀態）。
3. **多分支 Adapter 擴展**——單分支拓寬為 M 條平行分支（各自 down/up 權重、RC、α），部署幾何 20 組 backbone→target 掃描平均 +3.36 pp（最高 +11.33 pp）；M≥2 超出 XC7Z020 容量，僅 RTL 模擬＋合成後估計。
4. **RC（Residual Correction）發現與硬體映射**——RC 是 Conv-Adapter **既有的** down-convolution Int8 偏置（非本作新發明）；本作系統性隔離其在 1W1A 的顯著較大實測效果（CIFAR-10→SVHN 部署幾何 +20~23 pp；2–8 bit 通常 ±0.3 pp、最大 1.4 pp），並映射為 accumulator 初始值——不新增加法器/DSP/管線級，其儲存（`ram_rc`）與組態位元組計入 adapter 成本。

平台：**PYNQ-Z2（Xilinx XC7Z020）**，100 MHz；訓練於 **PyTorch + Brevitas**，硬體合成於 **FINN v0.9（Docker）+ Vivado 2022.2**。

---

## 二、資料夾結構

| 資料夾 | 內容 | 來源主機 |
|---|---|---|
| [`AI_model_train/`](AI_model_train/) | 1W1A QAT 與 Conv-Adapter 遷移的全部程式碼、各實驗 runner、預訓練 backbone、結果 CSV | RTX 4090 + A6000 |
| [`FINN_Compile/`](FINN_Compile/) | FINN end-to-end dataflow 合成（Docker 內）：end2end notebook、CNV 模型、匯出之 ONNX | 本地 FINN |
| [`RTL/`](RTL/) | **部署版（compactness N-task、cfg 可寫）** Adapter / Super Wrapper / 8 單元 `cfg_hub` 的 `.v` 與打包 `.tcl`；throughput 變體與舊版存於 `RTL/variant_throughput/` | 本地 |
| [`SoC/`](SoC/) | 頂層 block design（PS + input/output DMA + dataflow partition） | 本地 Vivado |
| [`FPGA/`](FPGA/) | 上板 `.bit`/`.hwh`、driver、runtime 參數（四種 build） | PYNQ-Z2 + 本地 |
| [`Synth_Sweep/`](Synth_Sweep/) | 多分支 M=1–4 合成掃描：RTL 產生器、M 分支 RTL、Vivado 報告與彙整 | 本地 Vivado |
| [`Figures_Analysis/`](Figures_Analysis/) | 資料驅動圖表與分析腳本（Fig 5.2 RC 機制探查、Fig 5.4/5.5、last-epoch 交叉檢核） | A6000 + 本地 |

每個資料夾內都有獨立的 `README.md` 做檔案層級說明。

---

## 三、端到端流程（5 個階段）

```
[1] 訓練 (AI_model_train)
    1W1A CNV backbone 預訓練 → 凍結 → 每個 target dataset 接 Conv-Adapter 遷移
        │  輸出：backbone .tar、adapter checkpoint、結果 CSV
        ▼
[2] 編譯 (FINN_Compile)   ← 在 FINN Docker 內
    Brevitas 匯出 ONNX → FINN streamline/折疊(fold)/dataflow 合成
        │  輸出：per-MVAU memblock .dat、StreamingDataflowPartition IP
        ▼
[3] RTL 整合 (RTL)
    每個 MVAU 外包一層 Adapter「Super Wrapper」；加入 cfg_hub；打包成 Vivado IP
        ▼
[4] SoC 縫合 (SoC)
    block design 接上 Zynq PS + input/output DMA + 縫合後的 dataflow partition → bitstream
        ▼
[5] 部署 (FPGA)
    .bit/.hwh + Python driver 上 PYNQ-Z2；runtime 換任務 = 透過 cfg_hub
    寫入該任務 25,088 B 參數（6,757 個 32-bit 寫入）（組態重寫 ≈1.86 ms，無 fabric reconfiguration）
```

---

## 四、四種 FPGA build（對應論文資源/功耗/跨平台表）

| Build | 資料夾 | Bitstream | 用途 |
|---|---|---|---|
| Backbone, throughput（異質 PE） | `FPGA/backbone_throughput/` | `resizer.bit` | 吞吐量基準（純 backbone） |
| MARS, throughput, 2-task（異質 PE） | `FPGA/MARS_throughput_2ds/` | `resizer_v1.bit` | 能效/吞吐量代表組態（一任務烘入、一任務可切） |
| Backbone, compactness（PE=1） | `FPGA/backbone_compact_pe1/` | `resizer.bit` | compactness 基準（純 backbone） |
| MARS, compactness, N-task（PE=1） | `FPGA/MARS_compact_5ds_pe1/` | `resizer_3ds_v3.bit` | 板上準確率正確性 + 五組任務模型 runtime 切換 |

> **PE** = Processing Element（MVAU 的平行折疊度）。throughput 採異質 per-layer PE 折疊；compactness 採均勻 PE=1，換取 LUT 餘裕以容納單一組完整 runtime 可寫之 active 任務狀態。

---

## 五、開發環境

| 階段 | 工具 |
|---|---|
| 訓練 | Python 3.8、PyTorch 2.4、Brevitas 0.12（1W1A QAT） |
| 合成 | FINN v0.9（Docker）、Vivado 2022.2 |
| 板端 | PYNQ-Z2（XC7Z020）、PYNQ runtime、100 MHz |

---

## 六、5 個資料集

| Dataset | 類別 | Train/Test | 原生解析度 | Modality | 領域 |
|---|---|---|---|---|---|
| CIFAR-10 | 10 | 50,000 / 10,000 | 32×32 | RGB | 一般自然物件（**預設 backbone**） |
| SVHN | 10 | 73,257 / 26,032 | 32×32 | RGB | 街景門牌數字 |
| STL10 | 10 | 5,000 / 8,000 | 96×96 | RGB | ImageNet 衍生（降採樣） |
| FashionMNIST | 10 | 60,000 / 10,000 | 28×28 | 灰階 | 服飾（複製通道） |
| CINIC10 | 10 | 90,000 / 90,000 | 32×32 | RGB | CIFAR-10 + 下採樣 ImageNet（總計 270k = 90k×3） |

全部統一調整成 **32×32×3** 輸入。

---

## 七、注意事項

- **Checkpoint 選點**：依 BNN-PYNQ 原始 trainer 流程，逐 epoch 以 test 集評估、保留最高分 epoch；checkpoint 選點規則見 `AI_model_train/`，並附 last-epoch 無選擇協定之交叉檢核（`Figures_Analysis/parse_lastepoch_b2.py`）。
- **大檔**：backbone（`*.tar`）、bitstream、ONNX、`*.dat` 皆為一般 git 物件（最大單檔 18.7 MB，皆在 GitHub 100 MB 限制內）。
- **未收錄**：原始逐 epoch 訓練 log（約 6.4 GB）與 Vivado/FINN 中間工程（數十 GB）不放；數據以各 `results/*.csv` 為準。
- **RTL 變體**：`RTL/` 主體為部署之 compactness N-task 變體（adapter 權重/RC/LUT 皆 cfg 可寫；`SIM_INIT_ROM` 巨集僅供模擬初始化）。throughput 變體（權重烘入）與早期 5 埠 `cfg_hub` 存於 `RTL/variant_throughput/` 供對照。

---

## 八、論文對應表（實驗 / 圖表 ↔ 程式碼與數據）

> 論文＝《MARS: A Reconfigurable Multi-Task-Capable Accelerator Architecture for Ultra-Low-Bit Streaming Inference》最終版。手繪架構示意圖（Fig 3.1–3.3、4.1–4.12、PE 折疊示意、RC in Hardware、Task Switch 流程、FSC 電路）為繪圖軟體製作，無對應程式碼；下表涵蓋所有**實驗與資料驅動圖表**。

| 論文位置 | 內容 | 程式碼 | 數據 |
|---|---|---|---|
| Table 3.1 / 3.2 | 位元寬度掃描（單分支 ±RC vs Full-FT；跨來源） | `AI_model_train/runners/run_configC_bits_rc.py`、`run_xx_to_others_bits.py` | `AI_model_train/results/*_configC_bits_rc/`、`*_to_others_bits/` |
| Table 3.3 / 3.4、式 3.13 | Adapter/backbone 幾何與 MACs（解析計算） | `AI_model_train/src/models_bitwidth/CNV_param.py`（幾何定義） | — |
| Table 5.1 | 資料集總覽 | `AI_model_train/src/bnn_pynq_train_bitwidth.py`（loader） | — |
| Table 5.3 / 5.4 | 寬版幾何多分支掃描（CIFAR 來源＋跨來源） | `runners/run_v6.py`、`run_v6_cross.py`、`run_configC_cross.py` | `results/configC_sw_multi/`、`*_configC_cross/` |
| Table 5.5 | Full-FT vs MARS M4（n=5 seed） | `runners/table56_5seed.py` | `results/table56_5seed/table56.csv` |
| Table 5.6＋§5.2.5 | M=1 vs M=4 五-seed 配對檢定＋last-epoch 交叉檢核 | `runners/_b2_a6_runner.py`、`Figures_Analysis/parse_lastepoch_b2.py` | `results/b2_significance/results.csv` |
| Table 5.8 | 寬版 vs 部署幾何 20 對比較 / Table 5.9–5.10 RC 消融（跨目標） | `runners/run_configA_bits_rc.py`、`run_v9.py` | `results/*_configA_bits_rc/`、`v9_cross_dataset/` |
| Table 5.7 / 5.18 | 部署幾何 20 組 backbone→target 掃描 | `runners/run_configA_cross.py`（＋`run_v9.py` CIFAR 來源） | `results/{svhn,stl10,fashionmnist,cinic10}_configA_cross/`、`v9_cross_dataset/` |
| §5.3.4 來源相依驗證 | FMNIST→SVHN 獨立重跑/seed2025 | `runners/fmnist_dep_verify.py`、`fmnist_s2025.py`、`fmnist_svhn200.py`、`fmnist_verify.py` | `results/fashionmnist_configA_verify/`、`fashionmnist_configC_SVHN_*/` |
| Table 5.12 / 5.13 / 5.14 | 四 build 資源/功耗/PE 折疊（post-implementation） | `SoC/`＋`FPGA/*/`（Vivado 工程重建腳本） | `FPGA/results/`（utilization/power 報告） |
| Table 5.15–5.17、Fig 5.4 / 5.5 | 多分支 M=1–4 合成掃描與權衡圖 | `Synth_Sweep/scripts/gen_multibranch_rtl.py` 等＋`Figures_Analysis/plot_fig5_4_5_5_tradeoff_power.py` | `Synth_Sweep/results_archive/`、`scripts/collect_tables.py` 彙整 |
| Fig 5.2 | RC 機制層級探查（偏置分佈/前激活/翻轉率） | `Figures_Analysis/rc_probe_fig5_2.py`（GPU 端）＋`plot_rc_mechanism_fig5_2.py` | `Figures_Analysis/rc_probe_out.json` |
| Fig 5.3 | 佈局圖（Vivado implemented design 截圖） | Vivado GUI（無腳本） | `FPGA/results/` |
| Table 5.19 / 5.20 | 跨平台吞吐/功耗/能效 | `FPGA/*/board_test_10k.py`（FPGA 端）；GPU/Jetson 量測腳本於已下線之 4090 主機（見論文方法敘述） | `FPGA/results/` |
| Table 5.22 / 5.23、§5.6 | 板上五任務切換準確率/資源/1.86 ms | `FPGA/MARS_compact_5ds_pe1/board_test_v3force.py`（板上五任務精度+切換延遲）、`runtime_3ds.py`（切換器）、`gen_3ds_cfg.py`（payload 產生） | `FPGA/MARS_compact_5ds_pe1/runtime_weights/`、`FPGA/results/` |
| Table 4.2、§4.3–4.5 | Adapter/Super Wrapper/cfg_hub RTL 與驗證 | `RTL/`（部署變體）、`RTL/gen_scripts/`、golden/testbench 於 `FINN_Compile/`＋`RTL/` | `RTL/hardware_assets/` |

---

---

## 九、重現指南（交接必讀）

### 9.1 環境
| 項目 | 版本 |
|---|---|
| OS | Ubuntu 20.04/22.04（訓練與合成皆於 Linux 驗證） |
| Python | 3.8（訓練環境;`pip install -r requirements.txt`） |
| PyTorch / Brevitas | 2.4.1 / 0.12.0 |
| FINN | v0.9（官方 Docker **原樣、未修改**;客製僅在前端輸入模型,見 `FINN_Compile/README.md`） |
| Vivado | 2022.2（所有資源/功耗/時序報告之工具版本） |
| 板端 | PYNQ-Z2 原廠 image（Python + `pynq` overlay API） |

路徑約定:訓練類腳本以環境變數 **`MARS_TRAIN_ROOT`** 指到訓練工作目錄（含 `paper_results_bitwidth/`、`pretrained_backbones/`）;Vivado `.tcl` 以 **`MARS_RTL_ROOT`／`MARS_ROOT`** 指到本 repo 對應資料夾。原始實驗跑在兩台 GPU 主機與本地 Vivado 機上,訓練/繪圖/分析類腳本已移除機器特定絕對路徑。硬體重建之 FINN build tree 由 `FINN_Compile/` 之 notebook 依步驟產生（見 §九、§十一）。

### 9.2 資料集與 checkpoint
- CIFAR-10 / SVHN / STL10 / FashionMNIST 由 torchvision **自動下載**;CINIC10 由 `bnn_pynq_train_bitwidth.py` 內建下載程序取得（官方 train/test 各 90k,valid 未用）。
- 預訓練 1W1A backbone（五個來源資料集各一）在 [`AI_model_train/backbones/`](AI_model_train/backbones/)（`*_1w1a.tar`）,可直接用;重訓指令見 `AI_model_train/README.md`。

### 9.3 最小軟體實驗（單筆遷移,約 30 分鐘 GPU）
```bash
pip install -r requirements.txt   # 首次:裝 torch/brevitas 等(見 §9.1)
cd AI_model_train/src
python bnn_pynq_train_bitwidth.py --mode adapter --net_bit 1 --dataset SVHN   --finetune_checkpoint ../backbones/cifar10_1w1a.tar   --epochs 200 --lr 0.005 --scheduler STEP --milestones 100,150 --batch_size 100   --random_seed 2024 --num_branches 1 --adapter_bit_width 1   --adapter_kernel 1 --adapter_act signed --adapter_alpha scalar   --adapter_mid_basis in --no_rc --adapter_bias
```
即部署幾何 M=1+RC 之 CIFAR-10→SVHN（對應 Table 5.18 第一列;best-epoch test 選點,規則見 `AI_model_train/`）。

### 9.4 硬體重現路徑
1. **adapter `.dat` / configuration blob**:**打包成品已在 repo**（`RTL/hardware_assets/` 97 個 `.dat`、`FPGA/.../runtime_weights/` 五任務 blob）,可直接用於模擬與部署。若要從 FINN 匯出之中間 `.dat` 重生:`RTL/gen_scripts/{prepack_adapter_dat,make_adp_contrib_luts,generate_mvau1234_golden}.py`,以環境變數 `MARS_DAT_SRC` 指中間 `.dat` 目錄（golden checkpoint `RC_m1_full.tar` 已隨附於 `gen_scripts/`）。
2. **RTL 模擬**:`RTL/verification/mvau{1..5}_testbench/`（五模組合計 43,520 向量;golden 由 `export_testbench_data.py` 自硬體佈局權重映像產生）;頂層模擬資產於 `RTL/verification/top_sim/`（`run_sim_top_*.tcl`、輸入 hex、baseline sim log）。
3. **Vivado 專案重建**:`RTL/tcl/make_project.tcl` → `package_ips.tcl` → `SoC/` block design → `RTL/tcl/build_bitstream.tcl`（OOC cache 注意事項見 `RTL/README.md`）。FINN 產生碼上的最小手動補丁由 `RTL/gen_scripts/patch_finn_ips.py` 自動施加（免 GUI）。
4. **PYNQ-Z2 部署**:把 `FPGA/<build>/` 整夾放上板,依 `FPGA/README.md` 執行 `board_test_10k.py`（吞吐/精度）與 `board_test_v3force.py`（五任務精度+切換延遲,`sw.switch()` 逐次量測）。

### 9.5 論文表格重現
見〈八、論文對應表〉:每張實驗表/資料驅動圖對應之 runner、輸出 CSV 與繪圖腳本。彙整層級（多 CSV → 論文表格數字）由 `Synth_Sweep/scripts/collect_tables.py` 與各 `results/README.md` 說明。


### 9.6 跑新實驗（給接手的人）

**改一個旗標就是一個新配置**——訓練主程式 `bnn_pynq_train_bitwidth.py` 全部以 CLI 旗標控制,不需改程式碼:

| 想改的東西 | 旗標 |
|---|---|
| 目標資料集 | `--dataset {CIFAR10,SVHN,STL10,FashionMNIST,CINIC10}` |
| 主幹來源 checkpoint | `--finetune_checkpoint ../backbones/<src>_1w1a.tar` |
| 分支數 M | `--num_branches {1,2,3,4}` |
| RC 開關 | `--no_rc`（關）/ 省略即開,配 `--adapter_bias` |
| 幾何:寬版 vs 部署 | 寬版 `--adapter_kernel 3 --adapter_alpha per_channel --adapter_mid_basis out`;部署 `--adapter_kernel 1 --adapter_alpha scalar --adapter_mid_basis in` |
| 位元寬度 | `--net_bit {1,2,4,8}` `--adapter_bit_width N` |
| seed | `--random_seed N` |

**批次掃描**:`AI_model_train/runners/run_*.py` 是上述主程式的批次包裝（迴圈跑多 dataset/M/seed,收 CSV）。要新增一組掃描,複製最接近的 runner、改它的 dataset/M/seed 清單即可,輸出自動落到 `results/<你的名稱>/`。

**加新資料集**:於 `src/bnn_pynq_train_bitwidth.py` 的 `get_dataloader()` 增一個分支(統一 resize 到 32×32×3、10 類),其餘流程不動。

**新硬體變體（新 M / 新折疊）**:`Synth_Sweep/scripts/gen_multibranch_rtl.py` 由 M=1 RTL 生成 M 分支變體;改折疊表在 `FINN_Compile/notebooks/pe1_cnv_end2end.ipynb` 的 folding cell。

> 所有腳本路徑以 `MARS_*` 環境變數或 `Path(__file__)` 解析,乾淨 clone 即可起跑(訓練類需先 `pip install -r requirements.txt`)。

---

## 十、本 release 的驗證範圍（與論文 §5.9 一致）

- **M=2–4 未上板**:超出 XC7Z020 容量;僅 RTL 模擬（40/40 bit-exact）與合成後估計,未 place-and-route。`Synth_Sweep` 報告皆為 synthesis-stage/vectorless 估計。
- **Checkpoint 以 test 集選點**（BNN-PYNQ 原流程）:絕對準確率為 best-epoch 操作點;last-epoch 無選擇交叉檢核見 `Figures_Analysis/parse_lastepoch_b2.py`。
- **FPGA 功耗為 Vivado 估計**,GPU/Jetson 為執行時實測;跨平台比較之 adapter 幾何不同（FPGA=部署 1×1、GPU/Jetson=寬版 3×3）。
- **GPU/Jetson 量測**:量測腳本收錄於 `Cross_Platform/`(NVML PowerMonitor + batch1000/n=10 協定),於 GPU/Jetson 主機依步驟執行即產生對應數據。
- **板上原始逐次量測 log**（50 次切換、10 次吞吐)僅保留統計摘要（`FPGA/results/onboard_measurements.md`）;量測腳本在 repo,可於板上重生。
- **Vivado 報告存檔**（`Synth_Sweep/results_archive/`、`FPGA/results/`）保留原建置機路徑字串,屬工具輸出原樣存證。
- 正式論文數據 vs 中間產物之區分見 `AI_model_train/results/README.md`（含探索批次註記）。

## 十一、大型建置產物的產生方式

本 release 收錄**重現論文所需的全部程式碼、環境版本與逐步驟指南**。以下大型建置產物（依其性質由對應工具鏈**依步驟產生**,不以二進位大檔隨附,以保持 repo 精簡）:

- **FPGA post-implementation 報告**（各 build 之 utilization/power/timing）:Vivado 建置產物。以 `SoC/` block design + `RTL/` 對應變體,依 §九.4 重跑 implementation 即產生;現存 `FPGA/results/` 已含三個 build 之 routed report（含 checksum `SHA256SUMS.txt`）,其中 MARS compactness 與論文 Table 5.24 逐項一致,MARS throughput 之論文值記於 `MARS_throughput_2ds/REPORT_NOTE.md`。
- **GPU/Jetson 跨平台量測**（Table 5.19/5.20）:量測腳本齊全於 `Cross_Platform/`,依其 README 於 GPU/Jetson 主機執行即產生逐次 timing/power 與彙整表。
- **板上量測**（Table 5.22/5.23,精度 ×10、切換 ×50）:量測腳本 `FPGA/MARS_compact_5ds_pe1/board_test_*.py` 齊全,於 PYNQ-Z2 執行即產生逐次紀錄;`FPGA/results/onboard_measurements.md` 附統計摘要。
- **五任務 runtime payload 與 Fig 5.2 probe**:成品 payload（`FPGA/.../runtime_weights/`,每任務 25,088 B）與 probe 輸出（`Figures_Analysis/rc_probe_out.json`）已在 repo,可直接用於部署與繪圖;產生程式（`gen_3ds_cfg.py`／`rc_probe_fig5_2.py`）以環境變數指定 checkpoint 目錄即可重生。

**證據層級**（論文 §5.9 之範圍陳述,非 repo 事項）:M=1 為板上驗證;M=2–4 提供 RTL 模擬（40/40 bit-exact,`RTL/verification/`,合計 43,520 向量）與合成後估計（`Synth_Sweep/`）。準確率為 test 集 best-epoch 操作點,附 last-epoch 交叉檢核腳本。

> 一句話:**重現所需的程式碼、環境版本、步驟均已備妥;大型建置產物依上述步驟由對應工具鏈產生。**

## 授權

MIT License（見 [`LICENSE`](LICENSE)）;第三方元件（FINN、Brevitas、PyTorch、FINN 產生之 RTL）保留其原始授權。

## 引用

若使用本專案，請引用碩士論文：
> Po-Chun Huang, "MARS: A Reconfigurable Multi-Task-Capable Accelerator Architecture for Ultra-Low-Bit Streaming Inference," Master's Thesis, National Chung Cheng University, 2026.

---
