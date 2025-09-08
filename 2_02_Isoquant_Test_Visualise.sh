#!/bin/bash

#SBATCH -p cpu,drive_cdt_gpu
#SBATCH -c 16
#SBATCH --mem=16G
#SBATCH --output=/scratch/prj/bcn_marzi_lab/Long-Reads-ALS/Tom_New_Dataset/outs/2_02_Isoquant_Test_Visualise_%a.log
#SBATCH --array=1-3

ml anaconda3

source ~/.bashrc
source activate isoquant
source parameters.sh

replica=$SLURM_ARRAY_TASK_ID
Neuron_Type=($(tail -n +2 Sample_Info_Long_Reads.csv | awk -v rep="$replica" -F, '$16 == rep {print $15}'))

isoquant_output="${ISOQUANT_DIR}/${Neuron_Type[0]}_Replica${replica}"

# The purpouse of this script is to generate an annotation map for each sample using the unfiltered bam files.
# This will then be QC'd and condenced before generating the final transcript quantification using hte filtered set of bam files.
# Transcripts will also be quantified in this script as a checkpoint to make sure the reads were QC'd and aligned propperly.


reference="GCA_000001405.15_GRCh38_full_analysis_set.fna"
annotation="GCA_000001405.15_GRCh38_full_analysis_set.refseq_annotation.gtf"
ext="sorted"


mkdir $ISOQUANT_DIR
mkdir $isoquant_output

# Plot genes in gene list (gene_id_isoquant.txt)
visualize.py $isoquant_output --gene_list $home_dir/Positive_Control_Genes_For_Isoquant.txt

# Make table of transcriptID and GeneID pairings (Can be used in downstream analysis to match transcripts to a gene)
cat $isoquant_output/OUT/OUT.transcript_models.gtf | awk '{print $2","$10","$11","$12}' | uniq | sed "s/;//g" | tail -n +4 > $isoquant_output/OUT/geneID_transcriptID_table.csv
