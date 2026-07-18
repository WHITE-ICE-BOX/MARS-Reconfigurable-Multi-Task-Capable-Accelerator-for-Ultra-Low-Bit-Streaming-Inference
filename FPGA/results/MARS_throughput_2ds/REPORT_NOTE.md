# MARS throughput (2-task) 之 post-implementation 報告

本目錄先前放置的三份 routed report 為 `backbone_throughput/` 之副本（誤植），已移除。

**論文正確值**（Table 5.12/5.13）：41,729 LUT (78.44%) / 53,285 FF / 99 BRAM / 2.215 W。

Vivado 的 utilization/power routed report 屬**建置產物**——接手者以 `SoC/` block design +
`RTL/`（throughput 變體）重跑 implementation 即會產生,不需另附。其餘三個 build 的 routed
report 已在對應目錄,其中 **MARS compactness 與論文 Table 5.24 逐項一致**。
