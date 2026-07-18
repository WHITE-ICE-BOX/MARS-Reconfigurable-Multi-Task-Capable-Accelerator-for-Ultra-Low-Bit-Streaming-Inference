#!/bin/bash
# Run all 30 multi-branch sims sequentially, collect RESULT lines.
ROOT=${MARS_ROOT}/mvau_multibranch_synth
OUT=$ROOT/sim/results_summary.txt
: > $OUT
for style in compact tp; do
  for M in 1 2 3 4; do
    for n in 1 2 3 4 5; do
      tag="${style}_m${M}_mvau${n}"
      res=$($ROOT/sim/$style/m$M/mvau$n/run.sh 2>&1 | tail -1)
      echo "$tag: $res" | tee -a $OUT
    done
  done
done
echo "ALL SIMS DONE" | tee -a $OUT
