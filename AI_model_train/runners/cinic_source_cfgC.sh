#!/bin/bash
set -u
source /home/esl/anaconda3/etc/profile.d/conda.sh
conda activate claude_repro
cd /mnt/8tb_hdd/barkie1_hdd/barkie_paper/paper/finn_brevitis/brevitas/src/brevitas_examples/bnn_pynq/claude/repro/claude/..
export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True
LOG=/mnt/8tb_hdd/barkie1_hdd/barkie_paper/paper/finn_brevitis/brevitas/src/brevitas_examples/bnn_pynq/claude/repro/claude/cinic_source_cfgC.log
PP=4
echo "######## CINIC10-source ConfigC START $(date) (cross M1-4 + bits 1,2,4; targets CIFAR10 SVHN STL10 FashionMNIST; gpu1) ########" >> "$LOG"
python claude/run_configC_cross_nf.py --source CINIC10 --targets CIFAR10 SVHN STL10 FashionMNIST --rc_only --parallel $PP --gpu 1 >> "$LOG" 2>&1 &
python claude/run_configC_bits_rc.py --source CINIC10 --targets CIFAR10 SVHN STL10 FashionMNIST --bits 1 2 4 --modes adapter_rc --parallel $PP --gpu 1 >> "$LOG" 2>&1 &
wait
echo "######## CINIC10-source ConfigC DONE $(date) ########" >> "$LOG"
