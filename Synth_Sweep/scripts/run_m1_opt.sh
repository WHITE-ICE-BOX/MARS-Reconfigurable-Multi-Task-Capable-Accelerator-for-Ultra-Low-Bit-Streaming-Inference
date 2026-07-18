#!/bin/bash
set -u
source /mnt/ssd/Xilinx/Vivado/2022.2/settings64.sh
ROOT=/home/barkie1/mvau_multibranch_synth
for b in compact3ds tp2ds; do
    d=$ROOT/$b/m1
    echo "==== [$(date)] OPT START $b/m1 ===="
    cd "$d" || exit 1
    vivado -mode batch -source $ROOT/gen/opt_report.tcl -tclargs "$d/vivado_stitch_proj" "$d/reports" \
        > "$d/opt_run.log" 2>&1
    echo "==== [$(date)] OPT DONE $b/m1 rc=$? ===="
done
echo "ALL M1 OPT DONE"
