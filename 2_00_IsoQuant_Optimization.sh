#!/bin/bash

#SBATCH -p cpu
#SBATCH -c 16
#SBATCH --mem=16G
#SBATCH --output=/scratch/prj/bcn_marzi_lab/Long-Reads-ALS/Tom_New_Dataset/outs/2_01_Isoquant_Annotation_%a.log
#SBATCH --array=1-8

ml anaconda3

source ~/.bashrc
source activate isoquant
source parameters.sh

replica=3

sample_names=($(tail -n +2 Sample_Info_Long_Reads.csv | awk -v rep="$replica" -F, '$16 == rep && $15 == "UMN" {print $1}'))
Neuron_Type=($(tail -n +2 Sample_Info_Long_Reads.csv | awk -v rep="$replica" -F, '$16 == rep {print $15}'))

sample_id_1=${sample_names[0]}
sample_id_2=${sample_names[1]}
sample_id_3=${sample_names[2]}
sample_id_4=${sample_names[3]}

isoquant_output="${ISOQUANT_DIR}/Optimization_Using_UMN3"

# The purpouse of this script is to optimise IsoQuant setting to generate an annotation map for each sample using the unfiltered bam files.
# Each step IsoQunat run is stored in a folder with a numbering system similar to versions (1.0 , 2.0 , 2.1 , 2.2.3 etc...)
# Sample UMN3 will be used as it is the only one that showed some UNC13A transcripts and can be used to monitor the changes
# in that gene. It also detected a second cryptic exon form of STMN2 and testing the different settings can tell us if that's
# is a robust finding or different filtering methods remove it.


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

case $SLURM_ARRAY_JOB_ID in 
   "1")

      echo "IsoQunant settings 1.0: Default"
      echo ""

      $isoquant_output=$isoquant_output/setting1.0

      isoquant.py \
         --reference ${REF_DIR}/$reference \
         --genedb ${REF_DIR}/$annotation \
         --bam "${BAM_DIR}/${sample_id_1}.${ext}.bam" "${BAM_DIR}/${sample_id_2}.${ext}.bam" "${BAM_DIR}/${sample_id_3}.${ext}.bam" "${BAM_DIR}/${sample_id_4}.${ext}.bam" \
         --complete_genedb --threads 16 \
         -o $isoquant_output 
         
      # Plot genes in gene list (gene_id_isoquant.txt)
      visualize.py $isoquant_output --gene_list $home_dir/Positive_Control_Genes_For_Isoquant.txt

      # Make table of transcriptID and GeneID pairings (Can be used in downstream analysis to match transcripts to a gene)
      cat $isoquant_output/OUT/OUT.transcript_models.gtf | awk '{print $2","$10","$11","$12}' | uniq | sed "s/;//g" | tail -n +4 > $isoquant_output/OUT/geneID_transcriptID_table.csv ;;

   # ==================================

   "2")
      echo "IsoQunant settings 2.0: --data_type nanopore"
      echo ""

      $isoquant_output=$isoquant_output/setting2.0

      isoquant.py \
         --reference ${REF_DIR}/$reference \
         --genedb ${REF_DIR}/$annotation \
         --bam "${BAM_DIR}/${sample_id_1}.${ext}.bam" "${BAM_DIR}/${sample_id_2}.${ext}.bam" "${BAM_DIR}/${sample_id_3}.${ext}.bam" "${BAM_DIR}/${sample_id_4}.${ext}.bam" \
         --complete_genedb --threads 16 \
         --data_type nanopore \
         -o $isoquant_output       
         
      # Plot genes in gene list (gene_id_isoquant.txt)
      visualize.py $isoquant_output --gene_list $home_dir/Positive_Control_Genes_For_Isoquant.txt

      # Make table of transcriptID and GeneID pairings (Can be used in downstream analysis to match transcripts to a gene)
      cat $isoquant_output/OUT/OUT.transcript_models.gtf | awk '{print $2","$10","$11","$12}' | uniq | sed "s/;//g" | tail -n +4 > $isoquant_output/OUT/geneID_transcriptID_table.csv ;;

   # ==================================

   "3")
      echo "IsoQunant settings 2.1: --data_type nanopore --model_construction_strategy sensitive_ont"
      echo ""

      $isoquant_output=$isoquant_output/setting2.1

      isoquant.py \ 
         --reference ${REF_DIR}/$reference \
         --genedb ${REF_DIR}/$annotation \
         --bam "${BAM_DIR}/${sample_id_1}.${ext}.bam" "${BAM_DIR}/${sample_id_2}.${ext}.bam" "${BAM_DIR}/${sample_id_3}.${ext}.bam" "${BAM_DIR}/${sample_id_4}.${ext}.bam" \
         --complete_genedb --threads 16 \
         --data_type nanopore \
         --model_construction_strategy sensitive_ont \
         -o $isoquant_output 
         
               # Plot genes in gene list (gene_id_isoquant.txt)
      visualize.py $isoquant_output --gene_list $home_dir/Positive_Control_Genes_For_Isoquant.txt

      # Make table of transcriptID and GeneID pairings (Can be used in downstream analysis to match transcripts to a gene)
      cat $isoquant_output/OUT/OUT.transcript_models.gtf | awk '{print $2","$10","$11","$12}' | uniq | sed "s/;//g" | tail -n +4 > $isoquant_output/OUT/geneID_transcriptID_table.csv ;;

   # ==================================

   "4")

      echo "IsoQunant settings 2.2: --data_type nanopore --transcript_quantification unique_inconsistent"
      echo ""

      $isoquant_output=$isoquant_output/setting2.2
      
      isoquant.py \
         --reference ${REF_DIR}/$reference \
         --genedb ${REF_DIR}/$annotation \
         --bam "${BAM_DIR}/${sample_id_1}.${ext}.bam" "${BAM_DIR}/${sample_id_2}.${ext}.bam" "${BAM_DIR}/${sample_id_3}.${ext}.bam" "${BAM_DIR}/${sample_id_4}.${ext}.bam" \
         --complete_genedb --threads 16 \
         --data_type nanopore \
         --transcript_quantification unique_inconsistent \
         -o $isoquant_output
      
      # Plot genes in gene list (gene_id_isoquant.txt)
      visualize.py $isoquant_output --gene_list $home_dir/Positive_Control_Genes_For_Isoquant.txt

      # Make table of transcriptID and GeneID pairings (Can be used in downstream analysis to match transcripts to a gene)
      cat $isoquant_output/OUT/OUT.transcript_models.gtf | awk '{print $2","$10","$11","$12}' | uniq | sed "s/;//g" | tail -n +4 > $isoquant_output/OUT/geneID_transcriptID_table.csv ;;

   # ==================================

   "5")

      echo "IsoQunant settings 2.3: --data_type nanopore --no_secondary"
      echo ""

      $isoquant_output=$isoquant_output/setting2.3

      isoquant.py \
         --reference ${REF_DIR}/$reference \
         --genedb ${REF_DIR}/$annotation \
         --bam "${BAM_DIR}/${sample_id_1}.${ext}.bam" "${BAM_DIR}/${sample_id_2}.${ext}.bam" "${BAM_DIR}/${sample_id_3}.${ext}.bam" "${BAM_DIR}/${sample_id_4}.${ext}.bam" \
         --complete_genedb --threads 16 \
         --data_type nanopore \
         --no_secondary \
         -o $isoquant_output

      # Plot genes in gene list (gene_id_isoquant.txt)
      visualize.py $isoquant_output --gene_list $home_dir/Positive_Control_Genes_For_Isoquant.txt

      # Make table of transcriptID and GeneID pairings (Can be used in downstream analysis to match transcripts to a gene)
      cat $isoquant_output/OUT/OUT.transcript_models.gtf | awk '{print $2","$10","$11","$12}' | uniq | sed "s/;//g" | tail -n +4 > $isoquant_output/OUT/geneID_transcriptID_table.csv ;;
   
   # ==================================

   "6")

      echo "IsoQunant settings 2.3.2: --data_type nanopore --no_secondary --min_mapq 10 --check_canonical"
      echo ""

      $isoquant_output=$isoquant_output/setting2.3.2

      isoquant.py \
         --reference ${REF_DIR}/$reference \
         --genedb ${REF_DIR}/$annotation \
         --bam "${BAM_DIR}/${sample_id_1}.${ext}.bam" "${BAM_DIR}/${sample_id_2}.${ext}.bam" "${BAM_DIR}/${sample_id_3}.${ext}.bam" "${BAM_DIR}/${sample_id_4}.${ext}.bam" \
         --complete_genedb --threads 16 \
         --data_type nanopore \
         --no_secondary --min_mapq 10 \
         --check_canonical \
         -o $isoquant_output

      # Plot genes in gene list (gene_id_isoquant.txt)
      visualize.py $isoquant_output --gene_list $home_dir/Positive_Control_Genes_For_Isoquant.txt

      # Make table of transcriptID and GeneID pairings (Can be used in downstream analysis to match transcripts to a gene)
      cat $isoquant_output/OUT/OUT.transcript_models.gtf | awk '{print $2","$10","$11","$12}' | uniq | sed "s/;//g" | tail -n +4 > $isoquant_output/OUT/geneID_transcriptID_table.csv ;;

   # ==================================

   "7")

      echo "IsoQunant settings 2.4: --data_type nanopore --min_mapq 10"
      echo ""

      $isoquant_output=$isoquant_output/setting2.4

      isoquant.py \
         --reference ${REF_DIR}/$reference \
         --genedb ${REF_DIR}/$annotation \
         --bam "${BAM_DIR}/${sample_id_1}.${ext}.bam" "${BAM_DIR}/${sample_id_2}.${ext}.bam" "${BAM_DIR}/${sample_id_3}.${ext}.bam" "${BAM_DIR}/${sample_id_4}.${ext}.bam" \
         --complete_genedb --threads 16 \
         --data_type nanopore \
         --min_mapq 10 \
         -o $isoquant_output

      # Plot genes in gene list (gene_id_isoquant.txt)
      visualize.py $isoquant_output --gene_list $home_dir/Positive_Control_Genes_For_Isoquant.txt

      # Make table of transcriptID and GeneID pairings (Can be used in downstream analysis to match transcripts to a gene)
      cat $isoquant_output/OUT/OUT.transcript_models.gtf | awk '{print $2","$10","$11","$12}' | uniq | sed "s/;//g" | tail -n +4 > $isoquant_output/OUT/geneID_transcriptID_table.csv ;;

   # ==================================

   "8")

      echo "IsoQunant settings 2.5: --data_type nanopore --matching_strategy loose"
      echo ""

      $isoquant_output=$isoquant_output/setting2.5


      isoquant.py \
         --reference ${REF_DIR}/$reference \
         --genedb ${REF_DIR}/$annotation \
         --bam "${BAM_DIR}/${sample_id_1}.${ext}.bam" "${BAM_DIR}/${sample_id_2}.${ext}.bam" "${BAM_DIR}/${sample_id_3}.${ext}.bam" "${BAM_DIR}/${sample_id_4}.${ext}.bam" \
         --complete_genedb --threads 16 \
         --data_type nanopore \
         --matching_strategy loose \
         -o $isoquant_output

      # Plot genes in gene list (gene_id_isoquant.txt)
      visualize.py $isoquant_output --gene_list $home_dir/Positive_Control_Genes_For_Isoquant.txt

      # Make table of transcriptID and GeneID pairings (Can be used in downstream analysis to match transcripts to a gene)
      cat $isoquant_output/OUT/OUT.transcript_models.gtf | awk '{print $2","$10","$11","$12}' | uniq | sed "s/;//g" | tail -n +4 > $isoquant_output/OUT/geneID_transcriptID_table.csv ;;


esac
  










