#!/bin/bash

#SBATCH -p cpu,drive_cdt_gpu
#SBATCH -c 8
#SBATCH --mem=8G
#SBATCH --output=outs/3_03_SUPPA2_PSI_Calculation.%a.log
#SBATCH --array=1-8

ml anaconda3
source ~/.bashrc
source activate SUPPA2

source parameters.sh
suppa_inputdir="$SUPPA_DIR/inputs"
suppa_events="$SUPPA_DIR/events"
suppa_psi="$SUPPA_DIR/psi"

conditions=($(sed '/UMN_4/d' Sample_Info_Long_Reads.csv | tail -n +2 | awk -F, '{print $17}' | sort -n | uniq))
condition=`echo ${conditions[$SLURM_ARRAY_TASK_ID-1]}`

mkdir $suppa_events
mkdir $suppa_events/$condition
mkdir $suppa_psi
mkdir $suppa_psi/$condition

gtf_file=$ISOQUANT_DIR/all_samples/OUT/OUT.extended_annotation.gtf # Annotation gtf transcripts + known and novel transcripts
tpm_file=$suppa_inputdir/Transcript_Counts_$condition.tsv

# Generate events files and PSI files ========================================================================

echo ""
echo "Generating Events ...."
echo ""

for event in A3 A5 AF AL MX RI SE ; do

    echo ""
    echo "Generating PSI for ${event} ...."
    echo ""

    # Separate psi calculations are done per splicing event type
    suppa.py psiPerEvent -e $tpm_file -i $suppa_events/All_Samples_${event}_strict.ioe -o $suppa_psi/$condition/${condition}_${event}
    
    # Here we replace enteries with nan and NA TPM with 0 as this causes an error
    rm $suppa_psi/$condition/${condition}_${event}_filtered.psi
    sed -e 's/nan/0/' $suppa_psi/$condition/${condition}_${event}.psi | sed -e 's/NA/0/' > $suppa_psi/$condition/${condition}_${event}_filtered.psi

done

