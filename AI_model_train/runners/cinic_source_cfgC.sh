#!/bin/bash
set -u
# source <conda.sh>  # 依你的 conda 安裝路徑
conda activate claude_repro
cd ${MARS_TRAIN_ROOT}/..
export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True
LOG=${MARS_TRAIN_ROOT}/cinic_source_cfgC.log
PP=4
echo "######## CINIC10-source ConfigC START $(date) (cross M1-4 + bits 1,2,4; targets CIFAR10 SVHN STL10 FashionMNIST; gpu1) ########" >> "$LOG"
python claude/run_configC_cross_nf.py --source CINIC10 --targets CIFAR10 SVHN STL10 FashionMNIST --rc_only --parallel $PP --gpu 1 >> "$LOG" 2>&1 &
python claude/run_configC_bits_rc.py --source CINIC10 --targets CIFAR10 SVHN STL10 FashionMNIST --bits 1 2 4 --modes adapter_rc --parallel $PP --gpu 1 >> "$LOG" 2>&1 &
wait
echo "######## CINIC10-source ConfigC DONE $(date) ########" >> "$LOG"
