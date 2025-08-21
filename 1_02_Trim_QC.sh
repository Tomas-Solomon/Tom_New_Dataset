#!/bin/bash

#SBATCH -p cpu
#SBATCH -c 16
#SBATCH --mem=16G
#SBATCH --array=1
#SBATCH --output=/scratch/prj/bcn_marzi_lab/Long-Reads-ALS/Tom_New_Dataset/outs/1_02_Trim_QC_%a.log


ml anaconda3

source ~/.bashrc
source activate LR_ALS

source parameters.sh

sample_id=`tail -n +2 Sample_Info_Long_Reads.csv | awk -F, '{print $1}' | head -n $SLURM_ARRAY_TASK_ID | tail -n 1`

# Make missing directories ==========================

mkdir $output_dir
mkdir $work_dir

# QC before trimming ================================

mkdir $QC_reports
mkdir $QC_reports/BT
mkdir $QC_reports/BT/$sample_id

echo "Starting NanoQC before trimming"
NanoQC_DIR="$QC_reports/BT/$sample_id/NanoQC"
mkdir $NanoQC_DIR
nanoQC -o $NanoQC_DIR/. $RAW_DIR/$sample_id.fastq.gz

echo "Starting NanoPlotfor untrimmed samples"

source activate NanoPlot # Activate nanoplot env (requires separate env as is not compatible with other packages)
echo "Starting NanoPlot before trimming"
NanoPlot_DIR="$QC_reports/BT/$sample_id/NanoPlot"
mkdir $NanoPlot_DIR
NanoPlot -t 8 --fastq $RAW_DIR/${sample_id}.fastq.gz --maxlength 40000 --plots dot --title $sample_id --prefix ${sample_id}_  --outdir $NanoPlot_DIR/

source activate LR_ALS #Reactivate long reads env


# Trimming and filtering ================================

input_folder="$RAW_DIR"

if [ $Remove_Barcodes == 'TRUE' ]
then

    # Barcode trimming using pychopper

    mkdir $TRIM_DIR/

    echo ""
    echo "Trimming barcodes"
    echo ""

    source activate pychopper
    pychopper $input_folder/${sample_id}.fastq.gz $TRIM_DIR/${sample_id}.fastq.gz \
        -k PCB114.24 \
        -r ${sample_id}_report.pdf
    
    #porechop -i $input_folder/${sample_id}.fastq.gz -o $TRIM_DIR/${sample_id}.fastq.gz

    input_folder="$TRIM_DIR"

fi

if [ $Trim_Reads == 'TRUE' ]
then

    mkdir $TRIM_DIR/

    echo ""
    echo "Filtering and Trimming"
    echo ""

    source activate LR_ALS #Reactivate long reads env
    chopper -q $min_q_score -l $min_length --threads 8 -i $input_folder/${sample_id}.fastq.gz | gzip > $TRIM_DIR/${sample_id}_tmp.fastq.gz & mv $TRIM_DIR/${sample_id}.fastq.gz
    echo "done"

fi

echo "Trimming and filtering settings for $sample_id:" > $TRIM_DIR/trim_and_filter_settings.txt
echo "Barcode removing was set to $Remove_Barcodes" >> $TRIM_DIR/trim_and_filter_settings.txt
echo "Trim and filter reads using chopper was set to $Trim_Reads" >> $TRIM_DIR/trim_and_filter_settings.txt


# QC after trimming ================================

source activate LR_ALS 

mkdir $QC_reports/AT
mkdir $QC_reports/AT/$sample_id

# NanoQC
echo ""
echo "Starting NanoQC after trimming"
NanoQC_DIR="$QC_reports/AT/$sample_id/NanoQC"
mkdir $NanoQC_DIR
nanoQC -o $NanoQC_DIR $TRIM_DIR/${sample_id}.fastq.gz

# NanoPlot
echo ""
source activate NanoPlot # Activate nanoplot env (requires separate env as is not compatible with other packages)
echo "Starting NanoPlot after trimming"
NanoPlot_DIR="$QC_reports/AT/$sample_id/NanoPlot"
mkdir $NanoPlot_DIR
NanoPlot -t 8 --fastq $TRIM_DIR/${sample_id}.fastq.gz --maxlength 40000 --plots dot --title $sample_id --prefix ${sample_id}_  --outdir $NanoPlot_DIR/

