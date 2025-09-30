#!/bin/bash

#SBATCH -p drive_cdt_gpu
#SBATCH -c 2
#SBATCH --mem=4G
#SBATCH --output=outs/3_02_SUPPA2_FilePrep.log

# ===== DESCRIPTION OF SCRIPT =========================================================================


# The purpouse of this script is to generate an annotation map for each sample using the unfiltered bam files.
# This will then be QC'd and condenced before generating the final transcript quantification using hte filtered set of bam files.
# Transcripts will also be quantified in this script as a checkpoint to make sure the reads were QC'd and aligned propperly.

# ======================================================================================================

ml anaconda3

source ~/.bashrc
source activate isoquant

source parameters.sh

reference="GCA_000001405.15_GRCh38_full_analysis_set.fna"
annotation="GCA_000001405.15_GRCh38_full_analysis_set.refseq_annotation.gtf"
ext="sorted"

mkdir $ISOQUANT_DIR


# Separate transcripts by experiment group ===========================================================================

# Declare array with list of conditions (UMN, UMN_NMD etc ...) and number of replicates

conditions=($(sed '/UMN_4/d' Sample_Info_Long_Reads.csv | tail -n +2 | awk -F, '{print $17}' | sort -n | uniq))
condition_list=($(sed '/UMN_4/d' Sample_Info_Long_Reads.csv | tail -n +2 | awk -F, '{print $17}'))
sample_list=($(sed '/UMN_4/d' Sample_Info_Long_Reads.csv | tail -n +2 | awk -F, '{print $1}'))
sample_number=`sed '/UMN_4/d' Sample_Info_Long_Reads.csv | tail -n +2 | wc -l | awk '{print $1}'`


samples_in_condition_list=() # Will store the samples names for each condition in the same order as the $condition_list array

# The first for loop assigns a list of columns headers to the samples_in_condition_list array (eg. "1,UMN_1,UMN_2,UMN_3")
for condition in "${conditions[@]}"; do

    columns_to_keep=""

    # This loop generates the list of columns to include per condition
    for n in $(seq 1 $sample_number); do

        if [ "$condition" == "${condition_list[$n]}" ]; then

            columns_to_keep="${BAM_DIR}/${sample_list[$n]}.${ext}.bam $columns_to_keep" # Using comma to separate each column name as required by csvcut
        
        fi

    done
    
    samples_in_condition_list+=("$columns_to_keep")

done


# Run isoquant


isoquant_output="$ISOQUANT_DIR/${condition_list[$SLURM_ARRAY_TASK_ID]}"

mkdir $ISOQUANT_DIR
mkdir $isoquant_output

isoquant.py \
   --reference ${REF_DIR}/$reference \
   --genedb ${REF_DIR}/$annotation \
   --bam ${samples_in_condition_list[$SLURM_ARRAY_TASK_ID]} \
   --complete_genedb --threads 16 \
   --data_type nanopore \
   -o $isoquant_output




