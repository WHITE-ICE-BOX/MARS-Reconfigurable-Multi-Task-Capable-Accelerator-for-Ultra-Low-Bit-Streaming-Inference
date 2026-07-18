#!/bin/bash
set -u
source /home/esl/anaconda3/etc/profile.d/conda.sh; conda activate claude_repro
cd /mnt/8tb_hdd/barkie1_hdd/barkie_paper/paper/finn_brevitis/brevitas/src/brevitas_examples/bnn_pynq/claude/repro/claude/..
export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True
LOG=/mnt/8tb_hdd/barkie1_hdd/barkie_paper/paper/finn_brevitis/brevitas/src/brevitas_examples/bnn_pynq/claude/repro/claude/cinic_source_b8.log
echo "######## CINIC10->others b8 START $(date) ########" >> "$LOG"
python claude/run_configC_bits_rc.py --source CINIC10 --targets CIFAR10 SVHN STL10 FashionMNIST --bits 8 --modes adapter_rc --parallel 4 --gpu 1 >> "$LOG" 2>&1
echo "######## CINIC10->others b8 DONE $(date) ########" >> "$LOG"
