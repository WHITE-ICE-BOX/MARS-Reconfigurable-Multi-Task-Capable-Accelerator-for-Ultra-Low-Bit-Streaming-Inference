================================================================================
 頂層 RTL TESTBENCH — 操作流程 + 結果
 mvau_adapter/golden/
================================================================================

目的
----
對 FINN stitch 頂層 (StreamingDataflowPartition_1) 做端到端 AXI-Stream
RTL 準確率量測，邏輯與 Zynq 上的 validate_test.py 一致。

  * tb_top_baseline.sv  — 跑原始未改的 FINN stitch（無 adapter）
  * tb_top_adapter.sv   — 跑 adapter 融合版本
                          (StreamingDataflowPartition_1_Adapter)

資料集：SVHN 測試集（FINN 模型原本是 CIFAR-10 訓練，再用 adapter 在 SVHN
微調；BASELINE 路徑「沒有」adapter，所以跑 SVHN 應該接近隨機猜測——
這個「接近隨機」的結果正是我們驗證 TB 接線正確與否的依據）。

預期 baseline 於 SVHN : ~6–12 %   (無 adapter → 幾乎隨機)
預期 adapter  於 SVHN : ~60–80 %  (adapter 恢復目標域準確率)


檔案清單
--------
  export_testbench_data.py    資料集 → images.hex + labels.hex
  tb_top_baseline.sv          baseline TB（8-bit AXIS in, 8-bit top-1 out）
  tb_top_adapter.sv           adapter TB（同 port 定義，換 DUT）
  patch_stitch_adapter.py     產生 StreamingDataflowPartition_1_Adapter.v
  StreamingDataflowPartition_1_Adapter.v   已經 patch 好的 stitch 包層
  run_sim_top_baseline.tcl    Vivado batch 驅動（baseline）
  run_sim_top_adapter.tcl     Vivado batch 驅動（adapter）
  images.hex / labels.hex     當前測試向量（最近一次 = SVHN 1000 張）
  sim_log_baseline_100.txt    100 張 baseline 完整 xsim log
  sim_log_baseline_1000.txt   1000 張 baseline 完整 xsim log


步驟 0 — 資料集準備（只做一次）
-------------------------------
# SVHN（需要 /tmp/test_32x32.mat，來源：
#   http://ufldl.stanford.edu/housenumbers/test_32x32.mat）
python3 /tmp/extract_svhn.py /tmp/test_32x32.mat /tmp/svhn_finn_dataset 2000

# CIFAR-10（備用，來源：
#   https://www.cs.toronto.edu/~kriz/cifar-10-python.tar.gz）
python3 /tmp/extract_cifar10.py /tmp/cifar-10-python.tar.gz \
        /tmp/cifar10_finn_dataset 10000


步驟 1 — 匯出 hex 測試向量
--------------------------
cd mvau_adapter/golden
python3 export_testbench_data.py \
        --dataset_dir /tmp/svhn_finn_dataset \
        --n 1000 --shuffle --out_dir .
# ⇒ images.hex  (N*3072 行，一行一個 hex byte)
# ⇒ labels.hex  (N 行，一行一個 hex byte)


步驟 2a — 用 Vivado batch 跑 baseline（最省事，但 stdout 會 buffer）
-------------------------------------------------------------------
cd mvau_adapter/golden
NUM_IMAGES=1000 vivado -mode batch -source run_sim_top_baseline.tcl
# Vivado 的 stdout 會被大量 buffer，沒辦法即時看進度；
# 要即時追蹤進度請改用步驟 2b。


步驟 2b — 直接呼叫 xsim（推薦，可即時看進度）
---------------------------------------------
# 注意：baseline 跟 adapter 使用不同的 FINN build tree：
#   baseline : /home/barkie1/mvau_pipeline/finn/finn_pipeline/...
#   adapter  : /home/barkie1/mvau_pipeline/finn/finn_pipeline_adapter/...
# stitch 專案雜湊 (vivado_stitch_proj_hv26s5y4) 兩邊相同，
# 要跑哪個變體就挑對應的上層目錄。
#
# (1) 第一次需要在 Vivado 開啟 stitch 專案一次，產生 sim 檔集；
#     之後可直接沿用已生成的 sim_1 build 目錄：
#     $STITCH_PROJ/finn_vivado_stitch_proj.sim/sim_1/behav/xsim/

# --- BASELINE ---
SIM=/home/barkie1/mvau_pipeline/finn/finn_pipeline/vivado_stitch_proj_hv26s5y4/finn_vivado_stitch_proj.sim/sim_1/behav/xsim

# --- ADAPTER ---
# SIM=/home/barkie1/mvau_pipeline/finn/finn_pipeline_adapter/vivado_stitch_proj_hv26s5y4/finn_vivado_stitch_proj.sim/sim_1/behav/xsim

cp images.hex $SIM/
cp labels.hex $SIM/
cd $SIM

# (2) 關鍵：sim_1/behav/xsim/ 裡面的 tb_top_baseline_vlog.prj
#     會把 -d "NUM_IMAGES=100" 寫死在每一行 source，
#     xvlog 命令列的 --define 會被它蓋掉，所以要先 sed：
sed -i 's/-d "NUM_IMAGES=100"/-d "NUM_IMAGES=1000"/g' \
       tb_top_baseline_vlog.prj
rm -rf xsim.dir/tb_top_baseline_behav xsim.dir/xil_defaultlib

# (3) 重新 xvlog + xelab（NUM_IMAGES 變動時都要重編）：
source /mnt/ssd/Xilinx/Vivado/2022.2/settings64.sh
xvlog --relax -L uvm --define NUM_IMAGES=1000 \
      -prj tb_top_baseline_vlog.prj
xelab --debug off --relax --mt 8 \
      -d "NUM_IMAGES=1000" \
      -L xil_defaultlib -L uvm -L unisims_ver -L unimacro_ver \
      -L secureip -L xpm \
      --snapshot tb_top_baseline_behav \
      xil_defaultlib.tb_top_baseline xil_defaultlib.glbl \
      -log elaborate.log

# (4) 用分段式 tclbatch 跑 sim，這樣進度才會即時輸出到 log：
cat > run_step_1000.tcl <<'EOF'
puts "TCL: starting 1000-image run"
run 10 ms
puts "TCL: at 10ms"
run 100 ms
puts "TCL: at 110ms"
run all
puts "TCL: run all returned"
quit
EOF
nohup xsim tb_top_baseline_behav \
      -tclbatch run_step_1000.tcl --nolog \
      > /tmp/xsim_baseline_1000.log 2>&1 &

# (5) 另一個 terminal 追蹤進度：
tail -f /tmp/xsim_baseline_1000.log


步驟 3 — adapter 融合版本
-------------------------
python3 patch_stitch_adapter.py
# ↑ 讀 finn_pipeline_adapter 下的 StreamingDataflowPartition_1.v，
#   產出 mvau_adapter/golden/StreamingDataflowPartition_1_Adapter.v
vivado -mode batch -source run_sim_top_adapter.tcl
# 或照步驟 2b 的 xsim 流程，但 snapshot 改成 tb_top_adapter_behav、
# 並把 SIM 指向 finn_pipeline_adapter 那顆 stitch 專案的 sim 資料夾。


結果
====

--- RUN 1 : baseline, N = 100, SVHN ------------------------------------------
  日期           : 2026-04-15
  工具           : Vivado / xsim 2022.2
  Sim 時間       : 50.857 ms   (5,085,661 cycles @ 100 MHz)
  實際耗時       : 約 41 分鐘 (直接 xsim, --debug off, 無 wdb dump)
  Label 分布     : [10,10,10,10,10,10,10,10,10,10]（分層、未打亂）

  報告：
    DUT           : StreamingDataflowPartition_1 (baseline)
    Images        : 100
    Correct       :   7
    Wrong         :  93
    Accuracy      :   7 / 100 = 7.0000 %

  解讀：baseline 在 SVHN ≈ 7 %，符合預期的「約 6 %」；
  因為 baseline 沒 adapter，SVHN 又是它沒訓練過的目標域，本來就應該
  接近隨機。這也確認 TB 接線、NHWC byte 順序、LabelSelect 輸出
  解讀都是對的。
  完整 log：sim_log_baseline_100.txt


--- RUN 2 : baseline, N = 1000, SVHN -----------------------------------------
  日期           : 2026-04-15
  工具           : xsim 2022.2（直接呼叫，分段 tclbatch）
  Sim 時間       : 500.830 ms  (50,082,961 cycles @ 100 MHz)
  實際耗時       : 8 小時 56 分鐘
                   （log 裡 "elapsed = 06:57:15" 是最後一段 run all；
                     前 2 小時是前段 run 10ms + run 100ms 的 pipeline 填充）
  Label 分布     : [114,91,91,94,104,106,95,93,109,103]（分層+打亂）

  報告：
    DUT           : StreamingDataflowPartition_1 (baseline)
    Images        : 1000
    Correct       :  115
    Wrong         :  885
    Accuracy      :  115 / 1000 = 11.5000 %

  解讀：baseline 在 SVHN ≈ 11.5 %，10 類任務下仍屬接近隨機；
  跟 RUN 1 的 7 % 在統計誤差 (±3 % @ N=100) 內一致，再次確認
  沒 adapter 的 CNV backbone 對 SVHN 基本上是瞎猜。
  完整 log：sim_log_baseline_1000.txt

  重要教訓：sim_1/behav/xsim/ 下 FINN 自動產生的
  tb_top_baseline_vlog.prj 把 `-d "NUM_IMAGES=100"` 寫死在
  每一行 source 的 xvlog 參數裡，cmdline 的 --define 會被它
  蓋掉。放大 N 一定要雙管齊下：
    sed -i 's/-d "NUM_IMAGES=100"/-d "NUM_IMAGES=1000"/g' \
        tb_top_baseline_vlog.prj
    # 再做乾淨的 xvlog + xelab（不要加 --incr），重新編譯 TB。


--- RUN 3 : adapter-fused, N = ?, SVHN ---------------------------------------
  <尚未執行>  — 用 run_sim_top_adapter.tcl 或用 xelab 產
                 tb_top_adapter_behav snapshot，SIM 記得切到
                 finn_pipeline_adapter 那顆 stitch 專案。


踩坑紀錄
--------
* NUM_IMAGES 是 TB 的 compile-time `define，改了就要重 xelab。
  TCL 驅動是透過 set_property verilog_define +
  xsim.compile.xvlog.more_options 傳入的。

* Vivado GUI/batch 的 stdout 緩衝很嚴重，$display 可能幾分鐘
  後才看得到。要即時追蹤進度請改用步驟 2b。

* xsim 在 `run -all` / `--runall` 時，若遇到只有空白/單行啟動
  命令的 Tcl 啟動檔（xsim.dir/<snapshot>/xsim_script.tcl），會
  提早結束並回傳成功。解法：用 -tclbatch 餵一份明確的 run + puts
  標記的 tcl 檔，就能正常跑。

* 一定要用 `--debug off` 且關掉 wdb dump。預設開波形 dump 時，
  baseline 100 張的 wdb 40 分鐘長到 1.1 GB 還跑不完；
  關掉之後同樣的 run 在 41 分鐘內完成，wdb 幾乎不佔空間。

* 第一張預測要到約 1 ms sim 時間才會出現（pipeline 很深）。
  100 張：sim 時間約 50 ms；1000 張：sim 時間約 500 ms +
  pipeline 暖機。實際耗時大致線性（這台機器約 1 分鐘 / ms sim）。

* baseline 與 adapter 各有獨立的 FINN build tree：
    baseline → /home/barkie1/mvau_pipeline/finn/finn_pipeline/...
    adapter  → /home/barkie1/mvau_pipeline/finn/finn_pipeline_adapter/...
  跑哪個就用哪一邊的 stitch 專案（雜湊 vivado_stitch_proj_hv26s5y4
  兩邊相同）。路徑別串錯，否則 adapter 會拿到沒 patch 的 top。
