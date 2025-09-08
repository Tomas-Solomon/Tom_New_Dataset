#!/bin/bash

#SBATCH -p cpu,drive_cdt_gpu
#SBATCH -c 16
#SBATCH --mem=16G
#SBATCH --output=/scratch/prj/bcn_marzi_lab/Long-Reads-ALS/Tom_New_Dataset/outs/3_02_SUPPA2_DifferentialSplicing.log

# ===== DESCRIPTION OF SCRIPT =========================================================================


# ======================================================================================================

ml anaconda3

source ~/.bashrc
source activate SUPPA2

source parameters.sh

mkdir $work_dir/SUPPA2


# Remove the first cell in IsoQuant tpm.tsv output ==========

# This is neccessary as SUPPA2 won't process the files otherwise

#sed 's/#feature_id\t//' $ISOQUANT_DIR/UMN_Replica1/OUT/OUT.transcript_model_grouped_tpm.tsv > $ISOQUANT_DIR/UMN_Replica1.transcript_model_grouped_tpm.tsv
cat $ISOQUANT_DIR/UMN_Replica2/OUT/OUT.transcript_model_grouped_tpm.tsv | awk '{print $1, $5}' | sed 's/#feature_id //' | sed 's/ /\t/' > UMN_Replica2_Ctrl.tmp.tsv & mv UMN_Replica2_Ctrl.tmp.tsv $ISOQUANT_DIR/UMN_Replica2_Ctrl.transcript_model_grouped_tpm.tsv
cat $ISOQUANT_DIR/UMN_Replica2/OUT/OUT.transcript_grouped_tpm.tsv | awk '{print $1, $5}' | sed 's/#feature_id //' | sed 's/ /\t/' >> $ISOQUANT_DIR/UMN_Replica2_Ctrl.transcript_model_grouped_tpm.tsv

cat $ISOQUANT_DIR/UMN_Replica2/OUT/OUT.transcript_model_grouped_tpm.tsv | awk '{print $1, $3}' | sed 's/#feature_id //' | sed 's/ /\t/' > UMN_Replica2_TDP43KD.tmp.tsv & mv UMN_Replica2_TDP43KD.tmp.tsv $ISOQUANT_DIR/UMN_Replica2_TDP43KD.transcript_model_grouped_tpm.tsv
cat $ISOQUANT_DIR/UMN_Replica2/OUT/OUT.transcript_grouped_tpm.tsv | awk '{print $1, $3}' | sed 's/#feature_id //' | sed 's/ /\t/' >> $ISOQUANT_DIR/UMN_Replica2_TDP43KD.transcript_model_grouped_tpm.tsv


gtf_file=$ISOQUANT_DIR/UMN_Replica1/OUT/OUT.transcript_models.gtf # Annotation gtf transcripts + known and novel transcripts
tpm_file_Ctrl=$ISOQUANT_DIR/UMN_Replica2_Ctrl.transcript_model_grouped_tpm.tsv
tpm_file_TDP43KD=$ISOQUANT_DIR/UMN_Replica2_TDP43KD.transcript_model_grouped_tpm.tsv

# Generate events file =========

#suppa.py generateEvents -i $gtf_file -o $work_dir/SUPPA2/UMN_Replicate2 -f ioe -e SE SS MX RI FL

suppa.py psiPerEvent -e $tpm_file_Ctrl -i work_dir/SUPPA2/UMN_Replicate2_RI_strict.ioe -o $work_dir/SUPPA2/psi/UMN_Replica2_Ctrl_RI
suppa.py psiPerEvent -e $tpm_file_TDP43KD -i work_dir/SUPPA2/UMN_Replicate2_RI_strict.ioe -o $work_dir/SUPPA2/psi/UMN_Replica2_TDP43KD_RI

rm $work_dir/SUPPA2/psi/UMN_Replica2_Ctrl_RI_filtered.psi
rm $work_dir/SUPPA2/psi/UMN_Replica2_TDP43KD_RI_filtered.psi 
sed -e 's/nan/0/' $work_dir/SUPPA2/psi/UMN_Replica2_Ctrl_RI.psi | sed -e 's/NA/0/' > $work_dir/SUPPA2/psi/UMN_Replica2_Ctrl_RI_filtered.psi
sed -e 's/nan/0/' $work_dir/SUPPA2/psi/UMN_Replica2_TDP43KD_RI.psi | sed -e 's/NA/0/' > $work_dir/SUPPA2/psi/UMN_Replica2_TDP43KD_RI_filtered.psi 

suppa.py diffSplice --method empirical --input $work_dir/SUPPA2/UMN_Replicate2_RI_strict.ioe --psi $work_dir/SUPPA2/psi/UMN_Replica2_Ctrl_RI_filtered.psi $work_dir/SUPPA2/psi/UMN_Replica2_TDP43KD_RI_filtered.psi --tpm $tpm_file_Ctrl $tpm_file_TDP43KD --area 1000 --lower-bound 0.05 -gc -o $work_dir/SUPPA2/UMN_Replica2



