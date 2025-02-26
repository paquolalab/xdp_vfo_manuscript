#!/bin/bash
set -o errexit -o pipefail

# alorenzetti 20240520
# description ####
# this script will
# learn about the alignments

# setting up ####
threads=10

# getting started ####
# setting up reference files
link_files () {

    # linking alignments, fastq,
    # log output, and metadata
    ln -s ../../_m/GRCh38_with_XDP_SVA__20240520_AL5RACE002__map-ont__minimap2.bam* .
    ln -s ../../../_m/base_called__summary.tsv .
    
}

# function to run jupyter notebooks
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
    # setting up reference files
    link_files

    # running seqkit stats for all
    # fastq files and saving to a table
    # seqkit stats -T *.fastq > fastq_stats_by_seqkit.tsv

    # running our report scripts
    while read i ; do
        nbname=`basename ${i/.ipynb/}`
        call_jupynb $nbname
    done < <(ls ../_h/*.ipynb)

}

# calling main function
main
