#!/bin/bash
# Top-level (Zynq top.bd, same boundary as the thesis M=1 numbers) synthesis
# for all 8 builds:
#   compact3ds: m1 m2 m3 m4      tp2ds: m1fix m2 m3 m4
# Per variant:
#   1. ensure variant dir (copy m1, swap in generated multi-branch RTL,
#      repackage the 5 adapter IPs)          [skip for compact m1]
#   2. refresh stitch project + re-export the StreamingDataflowPartition_1 IP
#      [skip for compact m1: its original export is the published artifact]
#   3. generate + run the Zynq top build tcl: fresh top.bd with the variant's
#      stitch IP swapped in, OOC synth, linked post-synth reports (+opt).
set -u
source /mnt/ssd/Xilinx/Vivado/2022.2/settings64.sh
export FINN_ROOT=${MARS_ROOT}/thesis/finn
ROOT=${MARS_ROOT}/mvau_multibranch_synth

ensure_variant () {
    local style=$1 rtlstyle=$2 M=$3 name=$4
    local src=$ROOT/$style/m1
    local dst=$ROOT/$style/$name
    if [ ! -d "$dst" ]; then
        rsync -a \
            --exclude 'vivado_stitch_proj/finn_vivado_stitch_proj.runs' \
            --exclude 'vivado_stitch_proj/finn_vivado_stitch_proj.cache' \
            --exclude '.Xil' --exclude 'reports' --exclude 'reports_global' --exclude 'reports_top' --exclude 'zynq' \
            --exclude '*.log' --exclude '*.jou' \
            "$src/" "$dst/"
    fi
    for n in 1 2 3 4 5; do
        cp $ROOT/rtl/$rtlstyle/m$M/mvau$n/MVAU${n}_Super_Wrapper.v \
           $ROOT/rtl/$rtlstyle/m$M/mvau$n/Stream_Adder_Threshold_mvau${n}.v \
           "$dst/mvau_adapter_ip/mvau$n/ip/src/"
    done
    if [ ! -f "$dst/repackage.log" ] || ! grep -q "ALL IPS REPACKAGED" "$dst/repackage.log"; then
        (cd "$dst" && vivado -mode batch -source $ROOT/gen/repackage_ips.tcl -tclargs "$dst" \
            > "$dst/repackage.log" 2>&1)
        grep -q "ALL IPS REPACKAGED" "$dst/repackage.log" || { echo "REPACKAGE FAILED $style/$name"; return 1; }
    fi
}

run_variant () {
    local style=$1 rtlstyle=$2 M=$3 name=$4 skip_prep=${5:-no}
    local dst=$ROOT/$style/$name
    if [ -f "$dst/reports_top/utilization_synth.rpt" ]; then
        echo "==== SKIP $style/$name (reports_top already present) ===="
        return 0
    fi
    echo "==== [$(date)] TOP-BUILD $style/$name (M=$M) ===="
    if [ "$skip_prep" != "yes" ]; then
        ensure_variant $style $rtlstyle $M $name || return 1
        (cd "$dst" && vivado -mode batch -source $ROOT/gen/refresh_stitch_ip.tcl -tclargs "$dst" \
            > "$dst/refresh_stitch.log" 2>&1)
        grep -q "STITCH IP EXPORTED" "$dst/refresh_stitch.log" || { echo "STITCH EXPORT FAILED $style/$name"; return 1; }
        # stitch runs no longer needed; reclaim disk
        rm -rf "$dst/vivado_stitch_proj/finn_vivado_stitch_proj.runs" 2>/dev/null
    fi
    python3 $ROOT/gen/gen_zynq_tcl.py "$dst" "$rtlstyle" || return 1
    rm -rf "$dst/zynq/finn_zynq_link"* "$dst/zynq/.Xil" 2>/dev/null
    (cd "$dst/zynq" && vivado -mode batch -source zynq_build.tcl > zynq_build.log 2>&1)
    local rc=$?
    echo "==== [$(date)] TOP-DONE $style/$name rc=$rc ===="
    grep -E "SYNTH STATUS|OPT_DESIGN FAILED|TOP REPORTS" "$dst/zynq/zynq_build.log" | head -3
    ls "$dst/reports_top/" 2>/dev/null
}

# compact m1: original stitch IP already exported — only zynq build
run_variant compact3ds compact 1 m1 yes
run_variant tp2ds      tp      1 m1fix
for M in 2 3 4; do run_variant compact3ds compact $M m$M; done
for M in 2 3 4; do run_variant tp2ds tp $M m$M; done
echo "ALL TOP VARIANTS DONE"
