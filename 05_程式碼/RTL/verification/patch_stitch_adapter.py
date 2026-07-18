#!/usr/bin/env python3
"""
Clone the FINN-generated stitch top (StreamingDataflowPartition_1.v) into a
new file StreamingDataflowPartition_1_Adapter.v where:

  * the outer module is renamed   StreamingDataflowPartition_1
                                 -> StreamingDataflowPartition_1_Adapter
  * the MVAU_hls_5 instance is rewired from
        StreamingDataflowPartition_1_StreamingDataflowPartition_1_MVAU_hls_5_0
        -> MVAU5_Super_Wrapper
    (which has an identical port signature, ports verified 2026-04-15)

Everything else (MVAU0/1/2/3/4/6/7/8, LabelSelect, SWG, DWC, FIFO, thresholds,
MVAU5's weight-streamer) is kept bit-identical so baseline and adapter results
are directly comparable.
"""
import argparse
import os
import re
import sys


SRC = ("/home/barkie1/mvau_pipeline/finn/finn_pipeline_adapter/"
       "vivado_stitch_proj_hv26s5y4/ip/src/StreamingDataflowPartition_1.v")

# N -> (FINN IP module name, adapter wrapper module name) for N=1..5
def _ip_mod(n):
    return ("StreamingDataflowPartition_1_StreamingDataflowPartition_1"
            f"_MVAU_hls_{n}_0")

SWAPS = [(_ip_mod(n), f"MVAU{n}_Super_Wrapper", n) for n in (1, 2, 3, 4, 5)]


def patch(src_path, dst_path):
    with open(src_path) as f:
        text = f.read()

    # 1. Rename only the outer top module.
    # The top declaration is `module StreamingDataflowPartition_1\n   (...` —
    # every other module in the file has a longer prefixed name, so anchor on
    # exactly the bare name followed by whitespace + '('.
    pat = r"(\bmodule\s+)StreamingDataflowPartition_1(\s*[\(\n])"
    text, n_mod = re.subn(pat,
                          r"\1StreamingDataflowPartition_1_Adapter\2",
                          text,
                          count=1)
    if n_mod != 1:
        sys.exit("could not find top-level `module StreamingDataflowPartition_1`")

    # matching endmodule: use the first `endmodule` that follows the renamed
    # header and precedes the next `module ` — keep naming neutral, no sentinel.

    # 2. Swap each MVAU_hls_N IP instance -> adapter wrapper.
    swap_report = []
    for ip_module, adapter_module, n in SWAPS:
        pat = (r"\b" + re.escape(ip_module) +
               r"\b(\s+StreamingDataflowPartition_1_MVAU_hls_" + str(n) + r"\b)")
        text, n_inst = re.subn(pat, adapter_module + r"\1", text, count=1)
        if n_inst != 1:
            sys.exit(f"could not find instance of {ip_module}")
        swap_report.append((ip_module, adapter_module))

    with open(dst_path, "w") as f:
        f.write("// AUTO-GENERATED from StreamingDataflowPartition_1.v by "
                "patch_stitch_adapter.py\n")
        f.write("// * top renamed      -> StreamingDataflowPartition_1_Adapter\n")
        for ip_module, adapter_module in swap_report:
            f.write(f"// * {ip_module} -> {adapter_module}\n")
        f.write(f"// source: {src_path}\n\n")
        f.write(text)

    print(f"wrote {dst_path}")
    print(f"  renamed top module   : 1 site")
    for ip_module, adapter_module in swap_report:
        print(f"  swapped              : {ip_module} -> {adapter_module}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", default=SRC)
    ap.add_argument("--dst",
                    default=os.path.join(os.path.dirname(__file__),
                                         "StreamingDataflowPartition_1_Adapter.v"))
    args = ap.parse_args()
    patch(args.src, args.dst)


if __name__ == "__main__":
    main()
