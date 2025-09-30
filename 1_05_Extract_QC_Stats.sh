#!/bin/bash -l

#SBATCH -p cpu,biomed_a30_gpu,biomed_a100_gpu
#SBATCH -c 16
#SBATCH --mem=16G
#SBATCH --output=/scratch/prj/bcn_marzi_lab/Long-Reads-ALS/Tom_New_Dataset/outs/1_04_BAMQC_%a.log
#SBATCH --array=21-28

source parameters.sh



sample_id=($(tail -n +2 Sample_Info_Long_Reads.csv | awk -F, '{print $1}'))

cell_type=($(tail -n +2 Sample_Info_Long_Reads.csv | awk -F, '{print $15}'))
replicate_number=($(tail -n +2 Sample_Info_Long_Reads.csv | awk -F, '{print $16}'))
group=($(tail -n +2 Sample_Info_Long_Reads.csv | awk -F, '{print $17}'))



rm $QC_reports/General_Summary_Stats_Fastq.tsv 
rm $QC_reports/SequencedBase_Quality.tsv

echo -e "Stat\tValues\tSample\tFile\tCell_Type\tReplicate\tGroup" > $QC_reports/General_Summary_Stats_Fastq.tsv
echo -e "Stat\tReads\tPercentage\tSample\tFile\tCell_Type\tReplicate\tGroup" > $QC_reports/SequencedBase_Quality.tsv

for n in $(seq 0 ${#sample_id[@]});
do

bt_nanostats_file="$QC_reports/BT/${sample_id[n]}/NanoPlot/${sample_id[n]}_NanoStats.txt"
at_nanostats_file="$QC_reports/AT/${sample_id[n]}/NanoPlot/${sample_id[n]}_NanoStats.txt"
bam_nanostats_file="$BAMQC_DIR/NanoPlot/${sample_id[n]}/${sample_id[n]}_NanoStats.txt"


# General Stats Table


bt_nanostats_general=($(cat $bt_nanostats_file | awk '{print $4}' | tail -n +2 | head -n 7))
bt_nanostats_header=($(cat $bt_nanostats_file | cut -d: -f 1 | tail -n +2 | head -n 7 | sed 's/ /_/g'))
at_nanostats_general=($(cat $at_nanostats_file | awk '{print $4}' | tail -n +2 | head -n 7))
at_nanostats_header=($(cat $at_nanostats_file | cut -d: -f 1 | tail -n +2 | head -n 7 | sed 's/ /_/g'))

for row in {0..6};
do

    echo -e "${bt_nanostats_header[$row]}\t${bt_nanostats_general[$row]}\t${sample_id[n]}\tbefore_trimming\t${cell_type[n]}\t${replicate_number[n]}\t${group[n]}" >> $QC_reports/General_Summary_Stats_Fastq.tsv
    echo -e "${at_nanostats_header[$row]}\t${at_nanostats_general[$row]}\t${sample_id[n]}\tafter_trimming\t${cell_type[n]}\t${replicate_number[n]}\t${group[n]}" >> $QC_reports/General_Summary_Stats_Fastq.tsv

done

# Reads Stats table


bt_nanostats_reads=($(cat $bt_nanostats_file | awk '{print $2}' | tail -n +11 | head -n 5 )) # add reads numbers above Q score
bt_nanostats_percentage=($(cat $bt_nanostats_file | awk '{print $3}' | tail -n +11 | head -n 5 | sed 's/(//' | sed 's/%)//')) # add percentage of bases above Q score
bt_nanostats_header=($(cat $bt_nanostats_file | cut -d: -f 1 | tail -n +11 | head -n 5 | sed 's/>//')) # Q score thresholds
bt_nanostats_reads[5]=`cat $bt_nanostats_file | awk '{print $4}' | head -n 6 | tail -n 1` # Add total number of reads
bt_nanostats_percentage[5]="100" # Add total number of reads % (i.e. 100%)
bt_nanostats_header[5]="Total_Reads" # Add name

at_nanostats_reads=($(cat $at_nanostats_file | awk '{print $2}' | tail -n +11 | head -n 5 )) # add reads numbers above Q score
at_nanostats_percentage=($(cat $at_nanostats_file | awk '{print $3}' | tail -n +11 | head -n 5 | sed 's/(//' | sed 's/%)//')) # add percentage of bases above Q score
at_nanostats_header=($(cat $at_nanostats_file | cut -d: -f 1 | tail -n +11 | head -n 5 | sed 's/>//')) # Q score thresholds
at_nanostats_reads[5]=`cat $at_nanostats_file | awk '{print $4}' | head -n 6 | tail -n 1` # Add total number of reads
at_nanostats_percentage[5]="100" # Add total number of reads % (i.e. 100%)
at_nanostats_header[5]="Total_Reads" # Add name



for row in {0..5};
do

    echo -e "${bt_nanostats_header[$row]}\t${bt_nanostats_reads[$row]}\t${bt_nanostats_percentage[$row]}\t${sample_id[n]}\tbefore_trimming\t${cell_type[n]}\t${replicate_number[n]}\t${group[n]}" >> $QC_reports/SequencedBase_Quality.tsv
    echo -e "${at_nanostats_header[$row]}\t${at_nanostats_reads[$row]}\t${at_nanostats_percentage[$row]}\t${sample_id[n]}\tafter_trimming\t${cell_type[n]}\t${replicate_number[n]}\t${group[n]}" >> $QC_reports/SequencedBase_Quality.tsv

done

done


flagstat_file="$BAMQC_DIR/${sample_id[n]}.sorted.flagstat"

bam_total_reads=($(cat $flagstat_file | awk '{print $1}' | head -n 2 | tail -n 1))
bam_mapped_reads=($(cat $flagstat_file | awk '{print $1}' | head -n 8 | tail -n 1))
