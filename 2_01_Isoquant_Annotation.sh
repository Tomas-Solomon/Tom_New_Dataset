#!/bin/bash

#SBATCH -p cpu,biomed_a30_gpu,biomed_a100_gpu
#SBATCH -c 16
#SBATCH --mem=16G
#SBATCH --output=/scratch/prj/bcn_marzi_lab/Long-Reads-ALS/Tom_New_Dataset/outs/2_01_Isoquant_Annotation_%a.log
#SBATCH --array=2-4

ml anaconda3

source ~/.bashrc
source activate isoquant
source parameters.sh

replica=$SLURM_ARRAY_TASK_ID

sample_names=($(tail -n +2 Sample_Info_Long_Reads.csv | awk -v rep="$replica" -F, '$16 == rep && $15 == "LMN" {print $1}'))
Neuron_Type=($(tail -n +2 Sample_Info_Long_Reads.csv | awk -v rep="$replica" -F, '$16 == rep {print $15}'))

sample_id_1=${sample_names[0]}
sample_id_2=${sample_names[1]}
sample_id_3=${sample_names[2]}
sample_id_4=${sample_names[3]}

isoquant_output="${ISOQUANT_DIR}/${Neuron_Type[0]}_Replica${replica}"

# The purpouse of this script is to generate an annotation map for each sample using the unfiltered bam files.
# This will then be QC'd and condenced before generating the final transcript quantification using hte filtered set of bam files.
# Transcripts will also be quantified in this script as a checkpoint to make sure the reads were QC'd and aligned propperly.


reference="GCA_000001405.15_GRCh38_full_analysis_set.fna"
annotation="GCA_000001405.15_GRCh38_full_analysis_set.refseq_annotation.gtf"
ext="sorted"

output_dir=`echo "isoquant${ext}"`


mkdir $ISOQUANT_DIR

#Check if file indexed, if not index it

for sample in ${sample_id_1} ${sample_id_2} ${sample_id_3} ${sample_id_4}; do

   if ! test -f ${BAM_DIR}/${sample}.${ext}.bam.bai; then

      echo ""
      echo "File Not Indexed"
      echo "Indexing Now ... "
      echo ""

      samtools index ${BAM_DIR}/${sample}.${ext}.bam
   fi

done

# Run isoquant


mkdir $ISOQUANT_DIR
mkdir $isoquant_output

isoquant.py \
   --reference ${REF_DIR}/$reference \
   --genedb ${REF_DIR}/$annotation \
   --bam "${BAM_DIR}/${sample_id_1}.${ext}.bam" "${BAM_DIR}/${sample_id_2}.${ext}.bam" "${BAM_DIR}/${sample_id_3}.${ext}.bam" "${BAM_DIR}/${sample_id_4}.${ext}.bam" \
   --complete_genedb --threads 16 \
   --data_type nanopore \
   -o $isoquant_output


# Create tsv files for each sample


