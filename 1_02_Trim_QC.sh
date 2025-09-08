#!/bin/bash

#SBATCH -p cpu,biomed_a30_gpu,biomed_a100_gpu
#SBATCH -c 16
#SBATCH --mem=16G
#SBATCH --array=13-20
#SBATCH --output=/scratch/prj/bcn_marzi_lab/Long-Reads-ALS/Tom_New_Dataset/outs/1_02_Trim_QC_%a.log


ml anaconda3

source ~/.bashrc
source activate LR_ALS

source parameters.sh

sample_id=`tail -n +2 Sample_Info_Long_Reads.csv | awk -F, '{print $1}' | head -n $SLURM_ARRAY_TASK_ID | tail -n 1`

# Make missing directories ==========================

mkdir -p $output_dir
mkdir -p $work_dir

# QC before trimming ================================

mkdir -p $QC_reports
mkdir -p $QC_reports/BT
mkdir -p $QC_reports/BT/$sample_id

echo "Starting NanoQC before trimming"
NanoQC_DIR="$QC_reports/BT/$sample_id/NanoQC"
mkdir -p $NanoQC_DIR
nanoQC -o $NanoQC_DIR/. $RAW_DIR/$sample_id.fastq.gz

echo "Starting NanoPlotfor untrimmed samples"

source activate NanoPlot # Activate nanoplot env (requires separate env as is not compatible with other packages)
echo "Starting NanoPlot before trimming"
NanoPlot_DIR="$QC_reports/BT/$sample_id/NanoPlot"
mkdir -p $NanoPlot_DIR
NanoPlot -t 8 --fastq $RAW_DIR/${sample_id}.fastq.gz --maxlength 40000 --plots dot --title $sample_id --prefix ${sample_id}_  --outdir $NanoPlot_DIR/


# Trimming and filtering ================================

input_folder="$RAW_DIR"

if [ $Remove_Barcodes == 'TRUE' ]
then

    # Barcode trimming using pychopper

    mkdir -p $TRIM_DIR/

    echo ""
    echo "Trimming barcodes"
    echo ""

    source activate pychopper
    pychopper $input_folder/${sample_id}.fastq.gz $TRIM_DIR/${sample_id}.fastq \
        -k PCB114 \
        -r ${sample_id}_report.pdf

    #porechop -i $input_folder/${sample_id}.fastq.gz -o $TRIM_DIR/${sample_id}.fastq.gz

    input_folder="$TRIM_DIR"

fi

input_folder="$TRIM_DIR"

if [ $Trim_Reads == 'TRUE' ]
then

    mkdir -p $TRIM_DIR/

    echo ""
    echo "Filtering and Trimming"
    echo ""

    source activate chopper
    chopper -q $min_q_score -l $min_length \
    --trim 10 \
    --threads 8 \
    -i $input_folder/${sample_id}.fastq | gzip > $TRIM_DIR/${sample_id}_tmp.fastq.gz

    mv $TRIM_DIR/${sample_id}_tmp.fastq.gz $TRIM_DIR/${sample_id}.chopper.fastq.gz

    echo "done"

fi

echo "Trimming and filtering settings for $sample_id:" > $TRIM_DIR/trim_and_filter_settings.txt
echo "Barcode removing was set to $Remove_Barcodes" >> $TRIM_DIR/trim_and_filter_settings.txt
echo "Trim and filter reads using chopper was set to $Trim_Reads" >> $TRIM_DIR/trim_and_filter_settings.txt


# QC after trimming ================================

source activate LR_ALS

mkdir -p $QC_reports/AT
mkdir -p $QC_reports/AT/$sample_id

# NanoQC
echo ""
echo "Starting NanoQC after trimming"
NanoQC_DIR="$QC_reports/AT/$sample_id/NanoQC"
mkdir -p $NanoQC_DIR
nanoQC -o $NanoQC_DIR $TRIM_DIR/${sample_id}.fastq

# NanoPlot
echo ""
source activate NanoPlot # Activate nanoplot env (requires separate env as is not compatible with other packages)
echo "Starting NanoPlot after trimming"
NanoPlot_DIR="$QC_reports/AT/$sample_id/NanoPlot"
mkdir -p $NanoPlot_DIR
NanoPlot -t 8 --fastq $TRIM_DIR/${sample_id}.fastq --maxlength 40000 --plots dot --title $sample_id --prefix ${sample_id}_  --outdir $NanoPlot_DIR/

