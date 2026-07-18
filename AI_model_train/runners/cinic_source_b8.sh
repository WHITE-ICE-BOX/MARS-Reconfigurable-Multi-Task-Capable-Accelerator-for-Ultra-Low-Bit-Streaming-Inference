#!/bin/bash
set -u
# source <conda.sh>; conda activate claude_repro
cd ${MARS_TRAIN_ROOT}/..
export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True
LOG=${MARS_TRAIN_ROOT}/cinic_source_b8.log
echo "######## CINIC10->others b8 START $(date) ########" >> "$LOG"
python claude/run_configC_bits_rc.py --source CINIC10 --targets CIFAR10 SVHN STL10 FashionMNIST --bits 8 --modes adapter_rc --parallel 4 --gpu 1 >> "$LOG" 2>&1
echo "######## CINIC10->others b8 DONE $(date) ########" >> "$LOG"
