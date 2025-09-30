#!/bin/bash

#SBATCH -p cpu,biomed_a30_gpu,biomed_a100_gpu
#SBATCH -c 16
#SBATCH --mem=64G
#SBATCH --output=/scratch/prj/bcn_marzi_lab/Long-Reads-ALS/Tom_New_Dataset/outs/2_03_Isoquant_AllSamples.log
#SBATCH --time=2-00:00:00

ml anaconda3

source ~/.bashrc
source activate isoquant
source parameters.sh

isoquant_output="${ISOQUANT_DIR}/all_samples_sensitive_ont"

# The purpouse of this script is to generate an annotation map for each sample using the unfiltered bam files.
# This will then be QC'd and condenced before generating the final transcript quantification using hte filtered set of bam files.
# Transcripts will also be quantified in this script as a checkpoint to make sure the reads were QC'd and aligned propperly.


reference="GCA_000001405.15_GRCh38_full_analysis_set.fna"
annotation="GCA_000001405.15_GRCh38_full_analysis_set.refseq_annotation.gtf"
ext="sorted"


mkdir $ISOQUANT_DIR
mkdir $isoquant_output

#Check if file indexed, if not index it


# Run isoquant


mkdir $ISOQUANT_DIR
mkdir $isoquant_output

isoquant.py \
   --reference ${REF_DIR}/$reference \
   --genedb ${REF_DIR}/$annotation \
   --bam ${BAM_DIR}/*.${ext}.bam \
   --complete_genedb --threads 16 \
   --no_secondary --min_mapq 10 \
   --data_type nanopore \
   --model_construction_strategy sensitive_ont \
   --sqanti_output \
   -o $isoquant_output

# sensitive_ont used instead of default_ont as cryptic transcript were being filtered (eg. MNAT1)


