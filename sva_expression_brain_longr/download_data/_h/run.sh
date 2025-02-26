#!/bin/bash
set -o errexit -o pipefail

# alorenzetti 20220914
# description ####
# this script will download
# long read RNA-seq data
# from ENCODE using as URL
# sources the manually obtained txt files
# provided in the _h directory

# setting up ####
# running params script
source /ceph/users/alorenzetti/sva_expression_brain_longr/_h/params.sh

# getting started ####
# initializing conda 
eval "$(conda shell.bash hook)"

# getting started ####
# copying lists and files
copy_lists_files () {
    cp ../_h/files*.txt .
    cp ../_h/dfam_sva_consensus.fa .
}

# downloading files
download_files () {
    local dir=$1
    local list=$2
    
    # creating dir and entering
    mkdir $dir
    cd $dir
    
    # using the command line
    # suggested by ENCODE UI
    xargs -L 1 curl -O -J -L < ../$list
    
    # exiting dir
    cd ..
}

# sorting and indexing bam files
# this function requires samtools
sort_index_bams () {
    local dir=$1
    
    # entering dir
    cd $dir
    
    # iterating
    for i in *.bam ; do
        prefix=${i/.bam/}
        
        # sorting
        samtools sort -@ $threads $i > ${prefix}_sorted.bam
        
        # indexing
        samtools index -b ${prefix}_sorted.bam
    done
    
    # exiting dir
    cd ..
}


# main function
main () {

    # activating conda env
    conda activate $conda_env_name

    # copying files
    copy_lists_files
    
    # downloading flnc fastq files
    download_files flnc_reads files-flnc-fastq.txt
    
    # downloading aligned unfiltered bam files
    download_files bam_unfiltered files-bam-unfiltered.txt
    
    # downloading aligned filtered bam files
    download_files bam_filtered files-bam-filtered.txt
    
    # downloading annotated transcripts files
    download_files anno_tx files-annotated-tx.txt
    
    # downloading quantification files
    download_files quant files-quant.txt
    
    # sorting and indexing unfiltered bams
    sort_index_bams bam_unfiltered
    
    # sorting and indexing filtered bams
    sort_index_bams bam_filtered
    
    # deactivating conda env
    conda deactivate
    
}

# running main function ####
main