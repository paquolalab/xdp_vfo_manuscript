#!/bin/bash
set -o errexit -o pipefail

# alorenzetti 20230328
# description ####
# this script will take
# the reads spanning the XDP-SVA
# hexamer according to
# /ceph/projects/xdp_striatal_organoids_RNA-seq/hisat2_with_xdp_sva_filter/proper_pairs_overlapping_SVA_5prime/_m/main.html
# and plot the region with alignments using Gviz

# getting started ####
# linking required files
link_files() {

    ln -s /ceph/genome/human/gencode37/GRCh38.p13.PRI/genome_with_xdp_sva/_m/GRCh38_with_XDP_SVA.primary_assembly.genome.fa .
    ln -s /ceph/users/alorenzetti/ref_transcriptomes_and_genomes/_m/sva_adj.bed .
    ln -s /ceph/projects/xdp_striatal_organoids_RNA-seq/hisat2_with_xdp_sva_filter/_m/*.bam .
    ln -s /ceph/projects/xdp_striatal_organoids_RNA-seq/metadata/_m/XDP_striatal_organoids_metadata.csv .

}

# sorting bam files
sort_bam() {

    local input_bam=$1
    
    samtools sort -o ${input_bam/.bam/_sorted.bam} $input_bam
    samtools index -b ${input_bam/.bam/_sorted.bam}
    
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

    # sorting bams and indexing
    for i in *bam ; do
        sort_bam $i
    done

    # calling function with appropriate filename
    call_jupynb report
}

# calling main function
main