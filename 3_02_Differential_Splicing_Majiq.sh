#!/bin/bash

#SBATCH -p cpu,drive_cdt_gpu
#SBATCH -c 16
#SBATCH --mem=16G
#SBATCH --output=/scratch/prj/bcn_marzi_lab/Long-Reads-ALS/Tom_New_Dataset/outs/3_02_Differential_Splicing_Majiq_Final.log

# ===== DESCRIPTION OF SCRIPT =========================================================================


# MAJIQ installation process ============

    # https://majiq.biociphers.org/app_download/
    
    # conda create -n majiq python=3.12
    # conda activate majiq
    # conda install -c bioconda htslib
    # conda install numpy # unneccessary if package is already installed.
    # conda install cython # unneccessary if package is already installed.
    # conda install pysam # unneccessary if package is already installed.

    
    # Set of path definitions for htslib. Without these majic wont install and won't run
    # export HTSLIB_LIBRARY_DIR=/users/$USER/.conda/pkgs/htslib-1.22-h566b1c6_0/lib
    # export HTSLIB_INCLUDE_DIR=/users/$USER/.conda/pkgs/htslib-1.22-h566b1c6_0/include
    # export LD_LIBRARY_PATH="/users/$USER/.conda/pkgs/htslib-1.22-h566b1c6_0/lib"

    # python3 -m venv env
    # source env/bin/activate
    # /users/$USER/.conda/envs/majiq/bin/pip3 install git+https://bitbucket.org/biociphers/majiq_academic.git

# MAJIQ v3 guide ============

    # https://biociphers.bitbucket.io/majiq-docs/index.html


# ======================================================================================================

ml anaconda3

source ~/.bashrc
source activate majiq3
source env/bin/activate

source parameters.sh

export HTSLIB_LIBRARY_DIR="/users/$USER/.conda/pkgs/htslib-1.22-h566b1c6_0/lib"
export HTSLIB_INCLUDE_DIR="/users/$USER/.conda/pkgs/htslib-1.22-h566b1c6_0/include"
export LD_LIBRARY_PATH="/users/$USER/.conda/pkgs/htslib-1.22-h566b1c6_0/lib"
export MAJIQ_LICENSE_FILE="$home_dir/majiq_licence.txt" #Defines where majiq license is stored (voila --licence won't work, hence I used this)

mkdir $work_dir/Majiq
mkdir $work_dir/Majiq/Final
mkdir $work_dir/Majiq/Final/build
mkdir $work_dir/Majiq/Final/psi
mkdir $work_dir/Majiq/Final/dpsi

# Generate annotation file =========

bash majiq_config.sh # Creates majiqexperiments.tsv automatically based on Samples_Info_Long_Reads.csv file

#rm -r $work_dir/Majiq/Final/build/* # Remove splicegraph directory if it aleady exists

#majiq build gencode.v48.chr_patch_hapl_scaff.annotation.gff3 $config_dir/majiq_experiments.tsv $work_dir/Majiq/Final/build --work-directory work_dir/Majiq/Final -j 2 --license $home_dir/majiq_licence.txt

# NMD Samples

echo ""
echo "Samples with NMD inhibition"
echo ""

majiq psi-coverage $work_dir/Majiq/Final/build/splicegraph.zarr $work_dir/Majiq/Final/psi/UMN_shield_NMD.psicov $work_dir/Majiq/Final/build/UMN_[1-3]_shield_NMD.sorted.sj
majiq psi-coverage $work_dir/Majiq/Final/build/splicegraph.zarr $work_dir/Majiq/Final/psi/UMN_NMD.psicov $work_dir/Majiq/Final/build/UMN_[1-3]_NMD.sorted.sj

majiq psi $work_dir/Majiq/Final/psi/UMN_shield_NMD.psicov --min-experiments 0.01 --splicegraph $work_dir/Majiq/Final/build/splicegraph.zarr --output-tsv $work_dir/Majiq/UMN_shield_NMD_psi.tsv --overwrite --license $home_dir/majiq_licence.txt
majiq psi $work_dir/Majiq/Final/psi/UMN_NMD.psicov --min-experiments 0.01 --splicegraph $work_dir/Majiq/Final/build/splicegraph.zarr --output-tsv $work_dir/Majiq/UMN_NMD_psi.tsv --overwrite --license $home_dir/majiq_licence.txt

majiq deltapsi --splicegraph $work_dir/Majiq/Final/build/splicegraph.zarr --output-voila $work_dir/Majiq/Final/dpsi/UMN_shield_noshield_NMD.dpsicov --output-tsv $work_dir/Majiq/UMN_shield_noshield_NMD_dpsi.tsv -psi1 $work_dir/Majiq/Final/psi/UMN_shield_NMD.psicov -psi2 $work_dir/Majiq/Final/psi/UMN_NMD.psicov --license $home_dir/majiq_licence.txt

majiq-v3 sg-coverage $work_dir/Majiq/Final/build/splicegraph.zarr $work_dir/Majiq/Final/build/UMN_shield_NMD.sgc $work_dir/Majiq/Final/build/UMN_[1-3]_shield_NMD.sorted.sj --overwrite --license $home_dir/majiq_licence.txt
majiq-v3 sg-coverage $work_dir/Majiq/Final/build/splicegraph.zarr $work_dir/Majiq/Final/build/UMN_NMD.sgc $work_dir/Majiq/Final/build/UMN_[1-3]_NMD.sorted.sj --overwrite --license $home_dir/majiq_licence.txt


# no NMD samples

echo ""
echo "Samples with no NMD inhibition"
echo ""

majiq psi-coverage $work_dir/Majiq/Final/build/splicegraph.zarr $work_dir/Majiq/Final/psi/UMN_shield.psicov $work_dir/Majiq/Final/build/UMN_[1-3]_shield.sorted.sj
majiq psi-coverage $work_dir/Majiq/Final/build/splicegraph.zarr $work_dir/Majiq/Final/psi/UMN.psicov $work_dir/Majiq/Final/build/UMN_[1-3].sorted.sj

majiq psi $work_dir/Majiq/Final/psi/UMN_shield.psicov --min-experiments 0.01 --splicegraph $work_dir/Majiq/Final/build/splicegraph.zarr --output-tsv $work_dir/Majiq/UMN_shield_psi.tsv --overwrite --license $home_dir/majiq_licence.txt
majiq psi $work_dir/Majiq/Final/psi/UMN.psicov --min-experiments 0.01 --splicegraph $work_dir/Majiq/Final/build/splicegraph.zarr --output-tsv $work_dir/Majiq/UMN_psi.tsv --overwrite --license $home_dir/majiq_licence.txt

majiq deltapsi --splicegraph $work_dir/Majiq/Final/build/splicegraph.zarr --output-voila $work_dir/Majiq/Final/dpsi/UMN_shield_noshield.dpsicov --output-tsv $work_dir/Majiq/UMN_shield_noshield_dpsi.tsv -psi1 $work_dir/Majiq/Final/psi/UMN_shield.psicov -psi2 $work_dir/Majiq/Final/psi/UMN.psicov --license $home_dir/majiq_licence.txt

majiq-v3 sg-coverage $work_dir/Majiq/Final/build/splicegraph.zarr $work_dir/Majiq/Final/build/UMN_shield.sgc $work_dir/Majiq/Final/build/UMN_[1-3]_shield.sorted.sj --overwrite --license $home_dir/majiq_licence.txt
majiq-v3 sg-coverage $work_dir/Majiq/Final/build/splicegraph.zarr $work_dir/Majiq/Final/build/UMN.sgc $work_dir/Majiq/Final/build/UMN_[1-3].sorted.sj --overwrite --license $home_dir/majiq_licence.txt

# Visualization

voila view $work_dir/Majiq/Final/build/splicegraph.zarr $work_dir/Majiq/Final/psi/UMN_shield_NMD.psicov $work_dir/Majiq/Final/build/UMN_shield_NMD.sgc
voila view $work_dir/Majiq/Final/build/splicegraph.zarr $work_dir/Majiq/Final/psi/UMN_shield.psicov $work_dir/Majiq/Final/build/UMN_shield.sgc


# Testing Voila lr
# voila lr -sg work_dir/Majiq/test/build/splicegraph.zarr --lr-gtf-file output_dir/IsoQuant/UMN_Replica3/OUT/OUT.transcript_models.gtf --lr-tsv-file output_dir/IsoQuant/UMN_Replica3/OUT/OUT.transcript_model_counts.tsv -o test_voila 
