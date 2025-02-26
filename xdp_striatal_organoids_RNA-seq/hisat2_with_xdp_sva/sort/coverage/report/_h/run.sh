#!/bin/bash
set -o errexit -o pipefail

# alorenzetti 20250113
# description ####
# this script will call
# a jupyter notebook

# setting up ####
# getting started ####
threads=20

# initializing conda 
# eval "$(conda shell.bash hook)"

# activating required env
# conda activate pb_envs

# getting started ####
# linking required files
link_files() {

    ln -s ../../../../../../20241202__hg38_with_xdp_sva/_h/GRCh38_with_XDP_SVA.primary_assembly.genome.fa .
    ln -s ../../../../../../20241202__hg38_with_xdp_sva/_h/GRCh38_with_XDP_SVA.primary_assembly.genome.fa.fai .
    ln -s ../../../../../../20241202__hg38_with_xdp_sva/_h/gencode.v37.with_xdp_sva.primary_assembly.annotation_sorted.gtf.gz .
    ln -s ../../../../../../20241202__hg38_with_xdp_sva/_h/gencode.v37.with_xdp_sva.primary_assembly.annotation_sorted.gtf.gz.tbi .
    ln -s ../../../../../analysis_speaqeasy/metadata/metadata_formated_for_manuscript/_m/xdp_bulkrnaseq_metadata.tsv .

    ln -s ../../../../../../xdp_data_obtention/analysis/PRJNA1004173__rosenkrantz_2024/_m/SraRunTable.csv .

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

    link_files
    call_jupynb main
}

# calling main function
main
