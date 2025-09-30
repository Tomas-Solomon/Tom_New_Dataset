#!/bin/bash -l

#SBATCH --job-name=SQANTI3
#SBATCH --partition=cpu
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --time=1-00:00:00
#SBATCH --output=outs/2_06_SQANTIQC.log

# ===== DESCRIPTION OF SCRIPT =========================================================================

# This script is run to comnpare the different IsoQuant runs to decide which parameters are best.

# SQANTI3 is used to evaluate the transcript maps to
# and give some QC metrics.

# SQANTI3 installation process ============

    # First SQANTI3 was downloaded

    #wget https://github.com/ConesaLab/SQANTI3/releases/download/v5.4/SQANTI3_v5.4.zip
    #mkdir sqanti3
    #unzip SQANTI3_v5.4.zip -d sqanti3
    #mv sqanti3/release_sqanti3/* sqanti3 # Move contents to parent directory sqanti3

    # Conda environment created

    #cd sqanti3
    #conda env create -f SQANTI3.conda_env.yml

    # Now the conda environment can be activated

# ==================================================

ml anaconda3

source parameters.sh
source ~/.bashrc

input_dir=$ISOQUANT_DIR/all_samples
output=$input_dir/SQANTI_Report

mkdir $output


# SQANTI QC

source activate sqanti3

echo ""
echo "Running SQANTI QC"
echo ""

python sqanti3/sqanti3_qc.py --isoforms $input_dir/OUT/OUT.transcript_models.gtf \
    --refGTF ${REF_DIR}/$annotation \
    --refFasta ${REF_DIR}/$reference_file \
    -o all_samples -d $output \
    --cpus 8 --report both 

