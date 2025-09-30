#!/bin/bash

#SBATCH -p cpu,drive_cdt_gpu
#SBATCH -c 8
#SBATCH --mem=8G
#SBATCH --output=/scratch/prj/bcn_marzi_lab/Long-Reads-ALS/Tom_New_Dataset/outs/1_03_Alignment_%a.log
#SBATCH --array=21-28

ml anaconda3
ml samtools

source ~/.bashrc
source activate LR_ALS

source parameters.sh

sample_id=`tail -n +2 Sample_Info_Long_Reads.csv | awk -F, '{print $1}' | head -n $SLURM_ARRAY_TASK_ID | tail -n 1`

mkdir -p $BAM_DIR

# Map reads
echo ""
echo "Started Mapping Reads"
minimap2 -ax splice --MD $REF_DIR/$reference_mmi $TRIM_DIR/${sample_id}.fastq -o $BAM_DIR/${sample_id}.sam #| samtools view -bS  > $BAM_DIR/${sample_id}.tmp.bam & mv $BAM_DIR/${sample_id}.tmp.bam $BAM_DIR/${sample_id}.bam
samtools view -bS $BAM_DIR/${sample_id}.sam > $BAM_DIR/${sample_id}.tmp.bam
mv $BAM_DIR/${sample_id}.tmp.bam $BAM_DIR/${sample_id}.bam
rm $BAM_DIR/${sample_id}.sam

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

