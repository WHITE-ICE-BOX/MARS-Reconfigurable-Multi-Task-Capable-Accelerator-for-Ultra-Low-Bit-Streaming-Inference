#!/bin/bash
# Snapshot each variant's reports_top into results_archive/<style>_<name>/
# (never overwrite an existing archive unless -f given).
ROOT=/home/barkie1/mvau_multibranch_synth
FORCE=${1:-}
for d in $ROOT/compact3ds/m1 $ROOT/compact3ds/m1gen $ROOT/compact3ds/m2 $ROOT/compact3ds/m3 $ROOT/compact3ds/m4 \
         $ROOT/tp2ds/m1fix $ROOT/tp2ds/m2 $ROOT/tp2ds/m3 $ROOT/tp2ds/m4; do
    [ -f "$d/reports_top/utilization_synth.rpt" ] || continue
    style=$(basename $(dirname $d)); name=$(basename $d)
    dst=$ROOT/results_archive/${style}_${name}
    if [ -d "$dst" ] && [ "$FORCE" != "-f" ]; then
        echo "KEEP existing archive: $dst"
        continue
    fi
    mkdir -p "$dst"
    cp -p "$d"/reports_top/*.rpt "$d"/reports_top/*.txt "$dst"/ 2>/dev/null
    echo "ARCHIVED $style/$name -> $dst"
done
