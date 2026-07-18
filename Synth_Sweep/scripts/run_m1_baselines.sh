#!/bin/bash
# Sequentially synth the two M=1 baselines and dump reports.
set -u
source /mnt/ssd/Xilinx/Vivado/2022.2/settings64.sh
ROOT=/home/barkie1/mvau_multibranch_synth
TCL=$ROOT/gen/synth_report.tcl

for b in compact3ds tp2ds; do
    d=$ROOT/$b/m1
    echo "==== [$(date)] START $b/m1 ===="
    cd "$d" || exit 1
    vivado -mode batch -source "$TCL" -tclargs "$d/vivado_stitch_proj" "$d/reports" \
        > "$d/synth_run.log" 2>&1
    rc=$?
    echo "==== [$(date)] DONE $b/m1 rc=$rc ===="
    ls -la "$d/reports/"
done
echo "ALL M1 BASELINES DONE"
