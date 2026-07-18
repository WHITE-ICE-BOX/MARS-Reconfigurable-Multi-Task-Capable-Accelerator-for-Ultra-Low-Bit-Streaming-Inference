#!/usr/bin/env python3
"""
Stage the 5 adapter IPs (mvau_adapter_ip/mvauN/ip/src/) into a single
flat directory for top-level adapter sim.

Module-name collisions handled here:
  * Stream_Adder_Threshold       -> renamed Stream_Adder_Threshold_MVAU{N}
                                    (per-IP file content differs; same
                                     module name would clash at compile.)
  * Stream_Splitter, Simple_FIFO : identical bytes across all 5 IPs;
                                    one canonical copy is kept.
  * Adapter_MVAU{N} / Adapter_Generic : already unique per IP, copied as-is.
  * MVAU{N}_Super_Wrapper         : already unique, but the SAT instance
                                    is rewritten to call the renamed module.
"""
import os
import re
import shutil
import sys

SRC_ROOT = "/home/barkie1/mvau_pipeline/mvau_adapter_ip"
DST = os.path.join(os.path.dirname(__file__), "adapter_assets")

ADAPTER_FILE = {
    1: "Adapter_MVAU1.v",
    2: "Adapter_MVAU2.v",
    3: "Adapter_MVAU3.v",
    4: "Adapter_MVAU4.v",
    5: "Adapter_Generic.v",
}


def main():
    os.makedirs(DST, exist_ok=True)

    # one canonical shared file
    shutil.copy(
        os.path.join(SRC_ROOT, "mvau1/ip/src/Stream_Splitter.v"),
        os.path.join(DST, "Stream_Splitter.v"),
    )
    shutil.copy(
        os.path.join(SRC_ROOT, "mvau1/ip/src/Simple_FIFO.v"),
        os.path.join(DST, "Simple_FIFO.v"),
    )

    for n in (1, 2, 3, 4, 5):
        ip_src = os.path.join(SRC_ROOT, f"mvau{n}/ip/src")
        # adapter
        shutil.copy(
            os.path.join(ip_src, ADAPTER_FILE[n]),
            os.path.join(DST, ADAPTER_FILE[n]),
        )
        # rename SAT module
        sat_text = open(os.path.join(ip_src, "Stream_Adder_Threshold.v")).read()
        new_name = f"Stream_Adder_Threshold_MVAU{n}"
        sat_renamed, n_sub = re.subn(
            r"\bmodule\s+Stream_Adder_Threshold\b",
            f"module {new_name}",
            sat_text,
            count=1,
        )
        if n_sub != 1:
            sys.exit(f"Failed to rename SAT module in mvau{n}")
        with open(os.path.join(DST, f"{new_name}.v"), "w") as f:
            f.write(sat_renamed)
        # patch wrapper to call renamed SAT
        wrap_text = open(os.path.join(ip_src, f"MVAU{n}_Super_Wrapper.v")).read()
        wrap_patched, n_inst = re.subn(
            r"\bStream_Adder_Threshold\b(\s+adder_thresh_inst\b)",
            new_name + r"\1",
            wrap_text,
            count=1,
        )
        if n_inst != 1:
            sys.exit(f"Failed to patch SAT instance in MVAU{n}_Super_Wrapper.v")
        with open(os.path.join(DST, f"MVAU{n}_Super_Wrapper.v"), "w") as f:
            f.write(wrap_patched)
        print(f"  staged MVAU{n}: wrapper + adapter + {new_name}")
    print(f"OK -> {DST}")


if __name__ == "__main__":
    main()
