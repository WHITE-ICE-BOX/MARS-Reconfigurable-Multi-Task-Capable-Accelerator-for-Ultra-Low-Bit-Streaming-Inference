# Cross_Platform — GPU (RTX 4090) 與 Jetson Nano 跨平台量測（論文 Table 5.19/5.20）

論文跨平台能效比較（FPGA vs GPU vs Jetson）之 **GPU/Jetson 端量測腳本**。原量測於 RTX 4090 主機；
GPU/Jetson 端量測腳本齊全,依下述步驟於對應主機執行即產生 Table 5.19/5.20 之數據。

> **量測協定**（與論文 §5.5 一致）：同 SVHN workload、batch 1000、10,000 張、n=10 次重複；
> 端到端計時（含 host 資料搬移）；功耗以 `PowerMonitor`（NVML，GPU）／tegrastats（Jetson）量測。
> FPGA 端為 Vivado 估計功耗、跑部署版 1×1 MARS；GPU/Jetson 跑 prior-art Conv-Adapter 3×3 寬版
> ——**不同 adapter 幾何、非同模型**（論文已明載此為 deployment-level 比較）。

## 檔案

| 檔案 | 平台 | 內容 |
|---|---|---|
| `gpu_rtx4090/benchmark_svhn.py` | RTX 4090 | 核心:`build_svhn_loader` + `PowerMonitor`(NVML) + 計時;被其餘 GPU 腳本 import |
| `gpu_rtx4090/benchmark_svhn_10x.py` | RTX 4090 | backbone / M=1-adapter 之 SVHN batch1000 ×10 量測 |
| `gpu_rtx4090/benchmark_cifar_10x.py` | RTX 4090 | CIFAR 版對照 |
| `gpu_rtx4090/bench_convadapter_k3_10x.py` | RTX 4090 | **prior-art Conv-Adapter 3×3 寬版**（Table 5.19/5.20 之 GPU 基線;kernel=3,對應 Transfer_k3_b1_adapter_e50 checkpoint） |
| `gpu_rtx4090/_b1_tables.py` | — | 由量測結果彙整成表 5.19/5.20 數值 |
| `gpu_rtx4090/_b1_bestof.py`、`_b1_autoidle.py` | RTX 4090 | 乾淨量測窗口挑選（等 GPU 閒置才量,避免污染;見論文定稿說明） |
| `jetson_nano/benchmark.py`、`benchmark_svhn.py` | Jetson Nano | Jetson 端 backbone / adapter 量測 |

## 執行

需 GPU/Jetson 主機、對應 checkpoint（`Cifar10_backbone.tar`、`RC_m1_*.tar`、`Transfer_k3_b1_adapter_e50` 等,
設 `MODEL_ROOT` 指向 checkpoint 目錄）與 SVHN 資料。GPU 端:

```bash
cd gpu_rtx4090
MODEL_ROOT=<checkpoint 目錄> python bench_convadapter_k3_10x.py   # GPU Conv-Adapter 3x3 基線
MODEL_ROOT=<checkpoint 目錄> python benchmark_svhn_10x.py          # backbone / M=1 adapter
python _b1_tables.py                                              # 彙整成論文表
```

## 執行需求

- 執行腳本即 print 逐次 timing/power 並可由 `_b1_tables.py` 彙整成論文表;`_b1auto.log` 為自動量測範例輸出。
- checkpoint 以 `MODEL_ROOT` 指定;可依 `AI_model_train/` 之步驟重訓產生,或向作者索取。
