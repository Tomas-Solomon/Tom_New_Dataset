#!/bin/bash

#SBATCH -p cpu,drive_cdt_gpu
#SBATCH -c 8
#SBATCH --mem=8G
#SBATCH --output=outs/3_04_SUPPA2_Differential_Splicing.%a.log
#SBATCH --time=00:30:00
#SBATCH --array=1-4

ml anaconda3
source ~/.bashrc
source activate SUPPA2

source parameters.sh
suppa_inputdir="$SUPPA_DIR/inputs"
suppa_events="$SUPPA_DIR/events"
suppa_psi="$SUPPA_DIR/psi"
suppa_dpsi="$SUPPA_DIR/dpsi"

control=`awk '{print $1}' Comparisons.tsv | head -n $SLURM_ARRAY_TASK_ID | tail -n 1`
treatment=`awk '{print $2}' Comparisons.tsv | head -n $SLURM_ARRAY_TASK_ID | tail -n 1`

tpm_file_control=$suppa_inputdir/Transcript_Counts_$control.tsv
tpm_file_treatment=$suppa_inputdir/Transcript_Counts_$treatment.tsv

mkdir $suppa_dpsi

#suppa.py diffSplice --method empirical --input $work_dir/SUPPA2/UMN_Replicate2_RI_strict.ioe --psi $work_dir/SUPPA2/psi/UMN_Replica2_Ctrl_RI_filtered.psi $work_dir/SUPPA2/psi/UMN_Replica2_TDP43KD_RI_filtered.psi --tpm $tpm_file_Ctrl $tpm_file_TDP43KD --area 1000 --lower-bound 0.05 -gc -o $work_dir/SUPPA2/UMN_Replica2

for event in A3 A5 AF AL MX RI SE ; do

    suppa.py diffSplice --method empirical \
        --input $suppa_events/All_Samples_${event}_strict.ioe \
        --psi $suppa_psi/$control/${control}_${event}.psi $suppa_psi/${treatment}/${treatment}_${event}.psi \
        --tpm $tpm_file_control $tpm_file_treatment \
        --area 1000 --lower-bound 0.05 -gc \
        -o $suppa_dpsi/${treatment}_${event}

done

# Make a unified .ioe, .dpsi and .psivec with tab separated columns

if [ $SLURM_ARRAY_TASK_ID == 1 ]; then rm $SUPPA_DIR/All_Samples_strict.ioe ; fi 
rm $SUPPA_DIR/${treatment}.dpsi
rm $SUPPA_DIR/${treatment}.psivec

if [ $SLURM_ARRAY_TASK_ID == 1 ]; then head -n 1 $suppa_events/All_Samples_A3_strict.ioe > $SUPPA_DIR/All_Samples_strict.ioe ; fi # Will add sample names for the psi values
head -n 1 $suppa_dpsi/${treatment}_A3.psivec > $SUPPA_DIR/${treatment}.psivec # Will add sample names for the psi values

for event in A3 A5 AF AL MX RI SE ; do

if [ $SLURM_ARRAY_TASK_ID == 1 ]; then tail -n +2 $suppa_events/All_Samples_${event}_strict.ioe >> $SUPPA_DIR/All_Samples_strict.ioe ; fi # Separating the gene and event type info from the location
tail -n +2 $suppa_dpsi/${treatment}_${event}.dpsi | sed 's/;/\t/' | sed 's/:/\t/' >> $SUPPA_DIR/${treatment}.dpsi # Separating the gene and event type info from the location
tail -n +2 $suppa_dpsi/${treatment}_${event}.psivec | sed 's/;/\t/' | sed 's/:/\t/' >> $SUPPA_DIR/${treatment}.psivec

done