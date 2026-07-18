# MARS throughput (2-task) 之 post-implementation 報告：遺失待補

**狀態**：本目錄先前放置的三份 routed report 經稽核發現為 `backbone_throughput/` 的
**逐位元副本（誤植）**，不能代表 MARS throughput build，已移除以免誤導。

**論文正確值**（Table 5.12/5.13）：41,729 LUT (78.4%) / 53,285 FF / 99 BRAM / 2.215 W。

**正確報告來源**：原始 Vivado implementation 工程（數十 GB 中間產物，未隨 release 保存）。
接手者若需此證據，須以 `SoC/` block design + `RTL/`（throughput 變體）重跑 implementation，
或向作者索取原工程封存。其餘三個 build 的 routed report 在對應目錄內，其中 **MARS compactness
與論文 Table 5.24 逐項一致**。
