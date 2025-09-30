#!/bin/bash

#SBATCH -p drive_cdt_gpu
#SBATCH -c 2
#SBATCH --mem=4G
#SBATCH --output=outs/3_02_SUPPA2_FilePrep.log

# ===== DESCRIPTION OF SCRIPT =========================================================================


# ======================================================================================================

ml anaconda3

source ~/.bashrc
source activate SUPPA2

source parameters.sh

isoquant_dir="$ISOQUANT_DIR/all_samples"
suppa_inputdir="$SUPPA_DIR/inputs"

mkdir $SUPPA_DIR
mkdir $suppa_inputdir


# Prepare TMP file ===========================================================================

# We start by copying the transcript_grouped_tmp fiile form IsoQuant which contians the
# TMPs of known transcripts. Then we merge the transcript_model_grouped_tpm.tsv file
# contianing the novel transcript TMPs.
# Finally we remove the .sorted file name extension from the headers of each column
# (eg. UMN.sorted -> UMN)

cp $isoquant_dir/OUT/OUT.transcript_grouped_tpm.tsv $suppa_inputdir/Transcript_Counts_All.tsv
cat $isoquant_dir/OUT/OUT.transcript_model_grouped_tpm.tsv | tail -n +2 >> $suppa_inputdir/Transcript_Counts_All.tsv
sed -i 's/.sorted//g' $suppa_inputdir/Transcript_Counts_All.tsv

# Separate transcripts by experiment group ===========================================================================

# Declare array with list of conditions (UMN, UMN_NMD etc ...) and number of replicates

conditions=($(sed '/UMN_4/d' Sample_Info_Long_Reads.csv | tail -n +2 | awk -F, '{print $17}' | sort -n | uniq))
condition_list=($(sed '/UMN_4/d' Sample_Info_Long_Reads.csv | tail -n +2 | awk -F, '{print $17}'))
sample_list=($(sed '/UMN_4/d' Sample_Info_Long_Reads.csv | tail -n +2 | awk -F, '{print $1}'))
sample_number=`sed '/UMN_4/d' Sample_Info_Long_Reads.csv | tail -n +2 | wc -l | awk '{print $1}'`


samples_in_condition_list=() # Will store the samples names for each condition in the same order as the $condition_list array

# The first for loop assigns a list of columns headers to the samples_in_condition_list array (eg. "1,UMN_1,UMN_2,UMN_3")
for condition in "${conditions[@]}"; do

    columns_to_keep="1" # starts with 1 which denotes the first column in the TPM tsv file, i.e. feature name
    
    # This loop generates the list of columns to include per condition
    for n in $(seq 1 $sample_number); do

        if [ "$condition" == "${condition_list[$n]}" ]; then

            columns_to_keep="$columns_to_keep,${sample_list[$n]}" # Using comma to separate each column name as required by csvcut
        
        fi

    done
    
    samples_in_condition_list+=("$columns_to_keep")

done

# Use array to create TPM files per condition

total_conditions=$((${#samples_in_condition_list[@]}-1)) #Since we start counting from zero

for n_condition in $(seq 0 $total_conditions); do


    echo "Assigning ${samples_in_condition_list[$n_condition]} samples to"
    echo "${conditions[$n_condition]} condition"

    # Convert to csv and then isolate first column and selected columns
    sed 's/\t/,/g' $suppa_inputdir/Transcript_Counts_All.tsv | csvcut -c ${samples_in_condition_list[$n_condition]} > $suppa_inputdir/Transcript_Counts_${conditions[$n_condition]}.tmp.csv
    mv $suppa_inputdir/Transcript_Counts_${conditions[$n_condition]}.tmp.csv  $suppa_inputdir/Transcript_Counts_${conditions[$n_condition]}.csv
    
    # Remove the first header (feature names). This is required by SUPPA2 as it only expexts sample headers.
    sed -i 's/#feature_id,//' $suppa_inputdir/Transcript_Counts_${conditions[$n_condition]}.csv 
    
    # Convert to tsv
    sed 's/,/\t/g' $suppa_inputdir/Transcript_Counts_${conditions[$n_condition]}.csv > $suppa_inputdir/Transcript_Counts_${conditions[$n_condition]}.tmp.tsv
    mv $suppa_inputdir/Transcript_Counts_${conditions[$n_condition]}.tmp.tsv $suppa_inputdir/Transcript_Counts_${conditions[$n_condition]}.tsv 
    rm $suppa_inputdir/Transcript_Counts_${conditions[$n_condition]}.tmp.tsv


done

# Generate suppa events files =============================================================================

gtf_file=$ISOQUANT_DIR/all_samples/OUT/OUT.transcript_models.gtf
suppa_events="$SUPPA_DIR/events"
mkdir $suppa_events

suppa.py generateEvents --boundary V -i $gtf_file -o $suppa_events/All_Samples -f ioe -e SE SS MX RI FL


# Quick Overview of Data for .log output file ==============================================================

head $suppa_inputdir/Transcript_Counts*.tsv
