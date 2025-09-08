#!/bin/bash

#SBATCH -p cpu,biomed_a30_gpu,biomed_a100_gpu,drive_cdt_gpu
#SBATCH -c 2
#SBATCH --mem=4G
#SBATCH --array=13-16
#SBATCH --output=/scratch/prj/bcn_marzi_lab/Long-Reads-ALS/Tom_New_Dataset/outs/1_01_Merge_Organize.%a.log

#awk -F, '{print $1, $8, $9, $14}' Sample_Info_Long_Reads.csv

source parameters.sh
sed -i 's/\r$//' Sample_Info_Long_Reads.csv # Add in case it gives you a "...'$'\r': No such file or directory" error

sample_number=$SLURM_ARRAY_TASK_ID

sample_id=`tail -n +2 Sample_Info_Long_Reads.csv | awk -F, '{print $1}' | head -n $sample_number | tail -n 1`
batch=`tail -n +2 Sample_Info_Long_Reads.csv | awk -F, '{print $8}' | head -n $sample_number | tail -n 1`
flowcell=`tail -n +2 Sample_Info_Long_Reads.csv | awk -F, '{print $9}' | head -n $sample_number | tail -n 1`
barcode=`tail -n +2 Sample_Info_Long_Reads.csv | awk -F, '{print $14}' | head -n $sample_number | tail -n 1`


# Merge fastq files and rename with sample id
mkdir -p $RAW_DIR

echo "copying and merging fastq.gz files for $sample_id"
cat $BASECALLED_DIR/batch${batch}_flowcell${flowcell}/barcode${barcode}/*.fastq.gz > $RAW_DIR/$sample_id.fastq.gz

echo "Completed copying. The file size of the new fastq.gz is:"
du -hs $RAW_DIR/$sample_id.fastq.gz


