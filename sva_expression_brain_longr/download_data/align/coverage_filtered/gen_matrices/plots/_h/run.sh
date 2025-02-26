#!/bin/bash
set -o errexit -o pipefail

# alorenzetti 20220918
# description ####
# this script will take
# coverage matrices computed
# by deeptools and make
# metaplots for SVAs

# setting up ####
# running params script
source /ceph/users/alorenzetti/sva_expression_brain_longr/_h/params.sh

# getting started ####
# initializing conda 
eval "$(conda shell.bash hook)"

# activating required env
conda activate $conda_env_name_r

# linking coverage matrices
# and sva bed files
link_files () {

    ln -s ../../_m/sva*bed .
    ln -s ../../_m/*tsv .
    ln -s ../../../../../_h/metadata.tsv .
    ln -s ../../../_m/n_reads_per_bam.tsv .
    
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
    
    # linking files
    link_files
    
    # calling function with appropriate filename
    call_jupynb 01_svas_and_coverage
    call_jupynb 02_sva_cats_and_enrichment
    call_jupynb 03_ad_exploratory_analysis
}

# calling main function
main