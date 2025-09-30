#!/bin/bash -l

#SBATCH -p cpu,biomed_a30_gpu,biomed_a100_gpu
#SBATCH -c 16
#SBATCH --mem=16G
#SBATCH --output=/scratch/prj/bcn_marzi_lab/Long-Reads-ALS/Tom_New_Dataset/outs/1_04_BAMQC_%a.log
#SBATCH --array=21-28


ml anaconda3
ml samtools

source ~/.bashrc
source parameters.sh

sample_id=`tail -n +2 Sample_Info_Long_Reads.csv | awk -F, '{print $1}' | head -n $SLURM_ARRAY_TASK_ID | tail -n 1`
BAMQC_DIR="$QC_reports/BAM"

# NanoComp

echo ""
echo "Starting NanoComp"

mkdir -p $BAMQC_DIR/NanoComp
mkdir -p $BAMQC_DIR/NanoComp/$sample_id

source activate NanoComp
NanoComp -t 8 --bam $BAM_DIR/${sample_id}.sorted.bam --outdir $BAMQC_DIR/NanoComp/$sample_id

# Cramino

mkdir -p $BAMQC_DIR/cramino

echo ""
echo "Starting cramino"

source activate cramino
cramino -t 8 --spliced --hist $BAM_DIR/$sample_id.sorted.bam > $BAMQC_DIR/cramino/$sample_id.cramino.out

# NanoPlot

echo ""
echo "Starting NanoPlot"
mkdir -p $BAMQC_DIR/NanoPlot
mkdir -p $BAMQC_DIR/NanoPlot/$sample_id

#source activate NanoPlot
#NanoPlot -t 8 --bam $BAM_DIR/$sample_id.sorted.bam --maxlength 40000 --plots dot --title $sample_id --prefix ${sample_id}_  --outdir $BAMQC_DIR/NanoPlot/$sample_id

# MultiQC

source activate multiqc
multiqc $BAMQC_DIR -f -n $BAMQC_DIR/multiqc/.

# =========================
# Remove duplicate reads and secondary alignments (this set will be used for quantification)
# =========================

# No nees ro remove low q-score reads as it was already done when basecalling (threshold 9)
# Removing secondary alingment can be benficial for isoform detection
# Removing supplementary mappings is not recommended for isoform detection
# Here is some info on alignment and alignment tags
# https://github.com/lh3/minimap2/issues/323


# In the next step we retain properly mapped pairs (-f 2) and 
# remove reads which fail the platform/vendor QC checks (-F 512),
# duplicate reads (-F 1024) and those which are unmapped (-F 12)

# First we mark duplicates

source activate picard
picard MarkDuplicates \
    I=$BAM_DIR/${sample_id}.sorted.bam \
    O=$BAM_DIR/unique/${sample_id}.sorted.markdup.bam \
    M=$BAMQC_DIR/markduplicate/${sample_id}.marked_dup_metrics.txt

mkdir -p $BAM_DIR/unique

samtools view -b -h -F 1548 -f 2 -q 10 $BAM_DIR/unique/${sample_id}.sorted.markdup.bam > $BAM_DIR/unique/${sample_id}.tmp.bam & mv $BAM_DIR/unique/${sample_id}.tmp.bam $BAM_DIR/unique/${sample_id}.unique.bam
samtools index $BAM_DIR/unique/${sample_id}.unique.bam
