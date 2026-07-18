#!/bin/bash
# Build the multi-branch variant projects:
#   compact3ds: m2 m3 m4            (m1 = original project, already reported)
#   tp2ds:      m1fix m2 m3 m4      (m1fix = M=1 with the per-PE adder
#                                    structure; the original tp m1 sources'
#                                    unified cfg arrays register-ize to ~100k
#                                    LUT and do not represent the deployed
#                                    build)
# Each variant: copy m1 (without stale runs), swap in generated RTL,
# repackage the 5 adapter IPs, then global synth + opt + reports.
set -u
source /mnt/ssd/Xilinx/Vivado/2022.2/settings64.sh
ROOT=${MARS_ROOT}/mvau_multibranch_synth

build_one () {
    local style=$1 rtlstyle=$2 M=$3 name=$4
    local src=$ROOT/$style/m1
    local dst=$ROOT/$style/$name
    echo "==== [$(date)] BUILD $style/$name (M=$M) ===="
    if [ ! -d "$dst" ]; then
        rsync -a \
            --exclude 'vivado_stitch_proj/finn_vivado_stitch_proj.runs' \
            --exclude 'vivado_stitch_proj/finn_vivado_stitch_proj.cache' \
            --exclude '.Xil' --exclude 'reports' --exclude 'reports_global' \
            --exclude '*.log' --exclude '*.jou' \
            "$src/" "$dst/"
    fi
    for n in 1 2 3 4 5; do
        cp $ROOT/rtl/$rtlstyle/m$M/mvau$n/MVAU${n}_Super_Wrapper.v \
           $ROOT/rtl/$rtlstyle/m$M/mvau$n/Stream_Adder_Threshold_mvau${n}.v \
           "$dst/mvau_adapter_ip/mvau$n/ip/src/"
    done
    cd "$dst" || exit 1
    vivado -mode batch -source $ROOT/gen/repackage_ips.tcl -tclargs "$dst" \
        > "$dst/repackage.log" 2>&1
    grep -q "ALL IPS REPACKAGED" "$dst/repackage.log" || { echo "REPACKAGE FAILED $style/$name"; return 1; }
    vivado -mode batch -source $ROOT/gen/synth_global_report.tcl \
        -tclargs "$dst/vivado_stitch_proj" "$dst/reports_global" \
        > "$dst/synth_global.log" 2>&1
    local rc=$?
    echo "==== [$(date)] DONE $style/$name rc=$rc ===="
    ls "$dst/reports_global/" 2>/dev/null
}

build_one tp2ds tp 1 m1fix
for M in 2 3 4; do build_one tp2ds tp $M m$M; done
for M in 2 3 4; do build_one compact3ds compact $M m$M; done
echo "ALL VARIANTS DONE"
