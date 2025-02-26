#!/bin/bash
set -o errexit -o pipefail

# alorenzetti 20220111
# description ####
# this script will take
# the XDP modified genome
# and predict G4 structure
# on sequences of interest

# setting up ####
# running params script
source /ceph/users/alorenzetti/xdp_g4_pred/_h/params.sh

# getting started ####
# initializing conda 
eval "$(conda shell.bash hook)"

# activating required env
# conda activate ${conda_env_name_r}_python27

# linking required files
link_files() {

    ln -s /ceph/genome/human/gencode37/GRCh38.p13.PRI/genome_with_xdp_sva/_m/GRCh38_with_XDP_SVA.primary_assembly.genome.fa .
    ln -s ../_h/QmRLFS-finder.py .
    ln -s /ceph/users/alorenzetti/ref_transcriptomes_and_genomes/_m/sva_adj.bed .

}

# def a function to call jupyter notebook
# and to convert to other formats
call_jupynb () {
    NOTEBOOK=$1

    cp ../_h/${NOTEBOOK}.ipynb tmp_${NOTEBOOK}.ipynb

    jupyter nbconvert --execute --ExecutePreprocessor.timeout=-1 --to notebook --stdout tmp_${NOTEBOOK}.ipynb > ${NOTEBOOK}.ipynb

    jupyter nbconvert --to html ${NOTEBOOK}.ipynb

    jupyter nbconvert --to script ${NOTEBOOK}.ipynb
    cp ${NOTEBOOK}.r ../_h/

    rm -f tmp_${NOTEBOOK}.ipynb
}

# main function
main () {

    # linking the required files
    link_files

    # calling function with appropriate filename
    call_jupynb report
}

# calling main function
main