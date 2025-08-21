#!/bin/bash

#SBATCH -p cpu
#SBATCH -c 16
#SBATCH --mem=16G
#SBATCH --output=/scratch/prj/bcn_marzi_lab/Long-Reads-ALS/Tom_New_Dataset/outs/1_04_BAMQC_%a.log
#SBATCH --array=1-4


ml anaconda3

source ~/.bashrc
source activate LR_ALS

source parameters.sh

sample_id=`tail -n +2 Sample_Info_Long_Reads.csv | awk -F, '{print $1}' | head -n $SLURM_ARRAY_TASK_ID | tail -n 1`
BAMQC_DIR="$QC_reports/BAM"

# NanoComp

echo ""
echo "Starting NanoComp"

mkdir $BAMQC_DIR/NanoComp
mkdir $BAMQC_DIR/NanoComp/$sample_id
NanoComp -t 8 --bam $BAM_DIR/${sample_id}.sorted.bam --outdir $BAMQC_DIR/NanoComp/$sample_id

# Cramino

mkdir $BAMQC_DIR/cramino

echo ""
echo "Starting cramino"
cramino -t 8 --spliced --hist $BAM_DIR/$sample_id.sorted.bam > $BAMQC_DIR/cramino/$sample_id.cramino.out

# NanoPlot

echo ""
echo "Starting NanoPlot"
mkdir $BAMQC_DIR/NanoPlot
NanoPlot -t 8 --bam $BAM_DIR/$sample_id.sorted.bam --maxlength 40000 --plots dot --title $sample_id --prefix ${sample_id}_  --outdir $BAMQC_DIR/NanoPlot/$sample_id
