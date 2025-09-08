#!/bin/bash

#SBATCH -p cpu
#SBATCH -c 16
#SBATCH --mem=16G
#SBATCH --output=/scratch/prj/bcn_marzi_lab/Long-Reads-ALS/Tom_New_Dataset/outs/1_03_Alignment_%a.log
#SBATCH --array=13-16

ml anaconda3
ml samtools

source ~/.bashrc
source activate LR_ALS

source parameters.sh

sample_id=`tail -n +2 Sample_Info_Long_Reads.csv | awk -F, '{print $1}' | head -n $SLURM_ARRAY_TASK_ID | tail -n 1`

reference_mmi=GCA_000001405.15_GRCh38_full_analysis_set.mmi
reference_fna=$REF_DIR/$reference

mkdir -p $BAM_DIR

# Map reads
echo ""
echo "Started Mapping Reads"
minimap2 -ax splice --MD $REF_DIR/$reference_mmi $TRIM_DIR/${sample_id}.fastq | samtools view -bS  > $BAM_DIR/${sample_id}.bam

# Sort bam files
echo ""
echo "Sorting bam file"
samtools sort -o $BAM_DIR/${sample_id}.sorted.bam $BAM_DIR/${sample_id}.bam
#rm $BAM_DIR/${sample_id}.bam
samtools index $BAM_DIR/${sample_id}.sorted.bam

# Flagstat Report
echo ""
echo "Generating Flagstat report"
mkdir -p $QC_reports/BAM
samtools flagstat $BAM_DIR/${sample_id}.sorted.bam > $QC_reports/BAM/${sample_id}.sorted.flagstat

