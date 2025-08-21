#!/bin/bash

#SBATCH -p biomed_a30_gpu, biomed_a100_gpu, interruptible_gpu
#SBATCH -c 2
#SBATCH --mem=32G
#SBATCH --output=/scratch/prj/bcn_marzi_lab/Long-Reads-ALS/Tom_New_Dataset/outs/0_basecalling.log
#SBATCH --gres=gpu

module load cuda
ml anaconda3

source ~/.bashrc
source activate LR_ALS

echo "Starting Dorado Basecaller"

dorado basecaller --model hac --data pod5/ \
    --min-qscore 9 \
    --no-trim \
    --emit-fastq \
    --kit-name SQK-PCB114-24 \
    > basecalled_files/batch2_flowcell_2/calls.bam


echo "Starting Dorado Demux"
dorado demux --output-dir <output-dir> --no-classify basecalled_files/batch2_flowcell_2/calls.bam

