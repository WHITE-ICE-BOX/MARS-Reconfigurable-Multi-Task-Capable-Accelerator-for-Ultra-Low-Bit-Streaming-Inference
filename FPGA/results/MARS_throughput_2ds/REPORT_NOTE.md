# MARS throughput (2-task) 之 post-implementation 報告

**論文數值**（Table 5.12/5.13）：41,729 LUT (78.44%) / 53,285 FF / 99 BRAM / 2.215 W。

Vivado 的 utilization / power / timing routed report 為**建置產物**。以 `SoC/` block design +
`RTL/`（throughput 變體）依 README §九.4 重跑 implementation 即產生本 build 的三份 report。
其餘三個 build 的 routed report 已在對應目錄（含 `../SHA256SUMS.txt` checksum）,其中
**MARS compactness 與論文 Table 5.24 逐項一致**。
