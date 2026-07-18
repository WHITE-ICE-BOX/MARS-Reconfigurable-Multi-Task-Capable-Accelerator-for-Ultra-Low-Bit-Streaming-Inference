# RTL — Adapter / Super Wrapper / cfg_hub 硬體描述

自研 RTL，把 FINN 產生的每個 **MVAU** 包成「**Super Wrapper**」（MVAU 主幹 + Adapter 旁路融合），
並提供 **Function Switch Controller（`cfg_hub`）** 執行時期任務切換控制器。共 5 個 MVAU 帶 Adapter（Super1–5），全部 1W1A。

> **本資料夾為部署之 compactness N-task 變體**（論文 §4.3–4.5）：adapter down/up 權重、RC、貢獻 LUT 皆 cfg 可寫（`SIM_INIT_ROM` 巨集僅供模擬初始化，合成後開機為空、由 host 載入）；`cfg_hub` 為 **8 位址單元／9 實體目的地** 版（`byte_addr[15:13]` 解碼，unit 0 依 bit[12] 分 MVAU0 低/高半），與論文 §4.5 及 Fig 4.9/4.10 一致。
> throughput 變體（adapter 權重以 `$readmemh` 烘入、僅閾值/分類器可切）與早期 5 埠 `cfg_hub` 保存於 [`variant_throughput/`](variant_throughput/) 供對照。

> 命名：論文中「Super Wrapper」對應 5 個帶 Adapter 的卷積層（MVAU1–5）。MVAU0/FC 層無 Adapter。

---

## 一、結構樹

```
RTL/
├── adapter/                         # ── Adapter 資料路徑（1×1 down → sign → 1×1 up + RC）──
│   ├── Adapter_MVAU1.v              #  MVAU1 的 Adapter（4-stage pipeline：latch/ROM→XNOR→popcount→accumulate）
│   ├── Adapter_MVAU2.v             #  MVAU2 Adapter
│   ├── Adapter_MVAU3.v             #  MVAU3 Adapter
│   ├── Adapter_MVAU4.v             #  MVAU4 Adapter
│   └── Adapter_MVAU5.v             #  MVAU5 的 Adapter（泛用/參數化版，原名 Adapter_Generic.v）
│
├── super_wrapper/                   # ── 每個 MVAU 的 Super Wrapper 與其子模組 ──
│   ├── MVAU{1..5}_Super_Wrapper.v   #  頂層：Splitter→(MVAU主幹 ‖ Adapter)→FIFO→Adder+Threshold
│   ├── Stream_Splitter_mvau{N}.v    #  把輸入串流複製給 MVAU 主幹(Path A)與 Adapter(Path B)
│   ├── Simple_FIFO_mvau{N}.v        #  深度 4096 同步 FIFO，吸收兩路延遲差、確保 cycle 對齊
│   ├── Stream_Adder_Threshold_mvau{N}.v # 把 Adapter 貢獻量與 MVAU partial-sum 相加後做 Q8 閾值二值化
│   └── Stream_Adder_mvau{N}.v       #  純加法版（部分 MVAU 用）
│
├── cfg_hub/
│   ├── adapter_cfg_hub.v            #  ★ AXI-Lite configuration hub（base 0x40010000，僅 19 LUT）
│   └── cls_cfg_bridge.v             #  ★ classifier(MVAU8) 權重 runtime 寫入橋：把 cfg_hub 的 cls_cfg_*
│                                    #     脈衝展開成對 MVAU8 memstream 的 8 筆 AXI-Lite 寫入
│                                    #    把 per-task 參數（thresholds、classifier 權重、5 層 adapter blob）
│                                    #    demux 到散落於 pipeline 的暫存器/RAM bank → 控制器無關的 runtime 切換
│
└── tcl/                             # ── Vivado 自動化腳本 ──
    ├── package_ips.tcl              #  把 5 個 MVAU+Adapter 打包成 Vivado IP
    ├── package_mvau1234.tcl         #  打包 MVAU1–4
    ├── package_mvau5_only.tcl       #  打包 MVAU5
    ├── make_project.tcl             #  建立 Vivado 工程
    └── build_bitstream.tcl          #  完整建置流程（stitch → zynq → bitstream）
│
├── mvau_core/                       # ── 改過的 MVAU 核心，三類改造（MVAU0–8 皆有改）──
│   ├── mvau1/ .. mvau5/             #  Conv1–5（帶 Adapter）。改造：MAC 解耦 thresholding，
│   │                                #    輸出『整數 partial-sum』給 Adapter 在 Stream_Adder_Threshold 融合後才二值化。
│   │                                #    關鍵檔：*_Matrix_Vector_Activate_Stream_Batch.v
│   ├── mvau0/ mvau6/ mvau7/         #  Conv0 / FC1 / FC2 threshold。改造（patch_finn_ips.py）：threshs_ROM
│   │                                #    由唯讀→cfg-可寫（加 cfg_wen/waddr/wdata）。關鍵檔：*_threshs_ROM_AUTO_1R.v（PATCHED）
│   └── mvau8/                       #  FC2/classifier。改造：權重 memstream 設 runtime-writeable，
│                                    #    由 cfg_hub/cls_cfg_bridge.v 經 AXI-Lite 寫入新 classifier 權重
│
├── hardware_assets/                 # ── RTL 消費的 .dat 權重（97 個）──
│   ├── mvau_{0..8}_memblock.dat     #  各 MVAU 的 FINN 二值權重 memblock
│   ├── adapter_{1..5}_{down,up,rc,alpha}.dat   #  各層 adapter 權重
│   └── *_contrib_lut.dat / thresh   #  contribution LUT、Q8 thresholds…
│
└── gen_scripts/                     # ── PyTorch 參數 → .dat/ROM 轉換腳本 ──
    ├── final_sw.py                  #  ★ 主匯出：載入 checkpoint → 產生全部 hardware_assets/*.dat（PE=1）
    ├── export_for_fpga.py           #  通用版匯出器
    ├── prepack_adapter_dat.py       #  把 adapter .dat 打包成 $readmemh 寬格式
    ├── make_adp_contrib_luts.py     #  產生 contribution LUT
    ├── generate_thresh_q8_mvau5.py  #  產生 MVAU5 Q8 threshold ROM
    ├── generate_mvau1234_golden.py / generate_mvau5_hw_aligned.py  #  golden / hw-aligned 資產
    ├── fix_rc_dat.py / gen_npy_golden.py   #  工具
    └── RC_m1_full.tar               #  final_sw.py 載入的 HW 匯出 checkpoint（deployed M1 + RC）
```

★ = 對應論文核心貢獻「單一 bitstream、免 fabric 重組態控制器之執行時期任務切換」。

> **PyTorch → 硬體流程**：訓練好的 checkpoint（`gen_scripts/RC_m1_full.tar`）經
> `final_sw.py` 轉成 `hardware_assets/*.dat`（FINN memblock + adapter 權重 + LUT/threshold），
> 由 `mvau_core/` 的 RTL 以 `$readmemh` 載入；`prepack_adapter_dat.py` 負責把 adapter 權重
> 打包成 ROM 寬格式。板端 runtime 切換則改用 `FPGA/.../runtime_weights/*.bin`（由相同來源產生）。

---

## 二、Adapter 資料路徑（4-stage pipeline）

```
輸入 → [S0] Input Latch + ROM Read（讀 down-proj 權重）
     → [S1] XNOR（1-bit 乘法）
     → [S2] Popcount（累計 +1/−1）
     → [S3] Accumulate（加上 RC = Int8 bias 作為 accumulator reset 初值）
     → Sign Extract（產生二值 hidden activation）
     → up-proj → Adapter 貢獻量
```
RC（Residual Correction）不需額外加法器/DSP/pipeline stage——只改 accumulator 的 reset 值。

---

## 三、Super Wrapper 資料流

```
        ┌──────────────► MVAU Core（FINN 原始，輸出整數 partial-sum）──┐
輸入 ──► Stream_Splitter                                               ├─► Stream_Adder_Threshold ─► 二值輸出
        └──► Adapter Core ─► (Simple_FIFO 對齊延遲) ─────────────────►─┘
```
`Stream_Adder_Threshold` 用合成期預計算的 contribution LUT 做縮放，**零 DSP**。

---

## 四、建置順序

1. `tcl/package_ips.tcl`（或 `package_mvau1234.tcl` + `package_mvau5_only.tcl`）打包 IP。
2. `tcl/make_project.tcl` 建工程、加入 `cfg_hub`。
3. `tcl/build_bitstream.tcl` 縫合並產生 bitstream（SoC 階段見 `../SoC/`）。

---

## 附錄：FINN 生成碼導覽 — 怎麼快速找到要改的訊號

接手整合最卡的一關,是在一坨 FINN 自動生成、名字像亂碼的 RTL 裡,找到「本論文要動的那個訊號」。以下是定位規則。

### 1. 模組命名規則（穩定,可依賴）

FINN 產生的每個運算單元都叫 `StreamingDataflowPartition_1_MVAU_hls_<N>_...`,`<N>` 是層編號,對照論文命名:

| FINN `MVAU_hls_<N>` | 論文單元 | 軟體層 | 帶 Adapter? |
|---|---|---|---|
| MVAU_hls_0 | MVAU0 | Conv1 | 否（PE=1,只改 threshold ROM） |
| MVAU_hls_1 ~ 5 | Super1 ~ Super5 | Conv2 ~ Conv6 | **是**（Super Wrapper 融合 adapter） |
| MVAU_hls_6 / 7 | MVAU6 / MVAU7 | FC1 / FC2 | 否（改 threshold ROM） |
| MVAU_hls_8 | MVAU8 | FC3（分類器） | 否（classifier memstream 可重載） |

### 2. 亂碼的部分（每次 build 會變,不可寫死）

- IP 生成目錄尾綴:`code_gen_ipgen_..._MVAU_hls_0_1bj4wrht` 那串 **8 字 hash 每次 FINN build 都不同**。
  → 用 wildcard 抓,不要寫死。`gen_scripts/patch_finn_ips.py` 已示範:`MVAU_hls_0_*` + `_resolve()` 確認唯一。
- stitch/zynq 工程裡的實例名帶隨機碼(`_0_0`、`vivado_stitch_proj_<rand>`)——同理用 glob。

### 3. 三類要找的訊號 + 定位指令

FINN 的 HLS 產生碼訊號名雖長,但 pattern 固定:

| 想找什麼 | 訊號 pattern | grep 指令 |
|---|---|---|
| **模組 AXI-Stream 邊界**（接 Super Wrapper 的地方） | `in0_V_TDATA/TVALID/TREADY`、`out_V_TDATA/TVALID/TREADY` | `grep -n "out_V_T" <MVAU_hls_N>.v` |
| **要暴露的 raw partial sum**（adapter 融合前的累加器輸出） | MV core 內 `Matrix_Vector_Activate_Stream_Batch` 的累加器 `dout`/`acc` | 見 `super_wrapper/Stream_Adder_Threshold_mvau*.v` 如何接該線 |
| **threshold / weight ROM**（cfg 可寫化的目標） | `threshs_ROM_AUTO_*`、`weights_*_ROM_*` | `grep -rln "threshs_ROM" <ipgen_dir>` |

### 4. 建議工具

- **Netron** 開 `FINN_Compile/onnx/end2end_cnv_w1a1_folded.onnx`:節點順序 = MVAU_hls_0..8 順序,一眼對到是哪一層。
- **`patch_finn_ips.py`** 直接讀它就懂「怎麼自動定位 + patch」:它示範找 port list 尾端 `out_V_TREADY` 插入 cfg port、找 `threshs_ROM` 換成 cfg 可寫版。改新層時複製其中一個 `IPS[...]` 條目、改 `rom_data_width/addr_width/depth` 即可。
- **Vivado hierarchy**（開 stitch 工程）:看 Super Wrapper 實際包住哪個 `MVAU_hls_N` 實例。

> 一句話:**模組名 `MVAU_hls_<N>` 和訊號 pattern（`out_V_T*`、`threshs_ROM`）是穩定錨點;只有目錄 hash 尾綴每次變,一律用 wildcard。** `patch_finn_ips.py` 是最完整的活範例。
