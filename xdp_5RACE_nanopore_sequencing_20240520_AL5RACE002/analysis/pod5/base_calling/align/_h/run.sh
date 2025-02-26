#!/bin/bash
set -o errexit -o pipefail

# alorenzetti 20240520
# description ####
# this script will convert
# bam to fastq and then
# will align them to the 
# reference genome using
# winnowmap2

# setting up ####
threads=20

# getting started ####
# setting up reference files
set_up_files () {
    # getting pod5 file
    ln -s ../../_m/base_called.bam 20240520_AL5RACE002.bam

    # getting winnowmap
    ln -s ../_h/Winnowmap/bin/winnowmap .

    # linking sva genome and annot
    ln -s /ceph/genome/human/gencode37/GRCh38.p13.PRI/genome_with_xdp_sva/_m/GRCh38_with_XDP_SVA.primary_assembly.genome.fa .
    ln -s /ceph/genome/human/gencode37/GRCh38.p13.PRI/genome_with_xdp_sva/gtf.PRI/_m/gencode.v37.with_xdp_sva.primary_assembly.annotation.gtf .

    # giving an alias to ref genome
    mv GRCh38_with_XDP_SVA.primary_assembly.genome.fa GRCh38_with_XDP_SVA.fa

    # indexing annotation file for IGV
    samtools faidx GRCh38_with_XDP_SVA.fa

    # extracting the XDP-SVA with flanking regions
    # arbitrarily chosen by inspecting IGV
    samtools faidx GRCh38_with_XDP_SVA.fa chrX:71430000-71453000 > GRCh38_with_XDP_SVA__chrX_71430000-71453000.fa
}

# minimap2 parameters taken from
# https://github.com/nanopol/xdp_sva/blob/main/repeatlengthdet.sh
run_minimap2 () {
    local barcode=$1
    local genotype=$2
    local preset=$3
    local ref=`ls "$genotype.fa"`

    # the MD tag is required for the methylation
    # call step, in order to output BAM methylation
    # converted for visualization on IGV
    minimap2 --MD -t $threads -a -x $preset $ref $barcode.fastq | \
    samtools sort -@ $threads > ${genotype}__${barcode}__${preset}__minimap2.bam.tmp

    samtools addreplacerg -r ID:$barcode -r BC:$barcode ${genotype}__${barcode}__${preset}__minimap2.bam.tmp |
    samtools view -b > ${genotype}__${barcode}__${preset}__minimap2.bam

    samtools index -b ${genotype}__${barcode}__${preset}__minimap2.bam
}

# winnowmap2
run_winnowmap2 () {
    local barcode=$1
    local genotype=$2
    local preset=$3
    local ref=`ls "$genotype.fa"`

    # the MD tag is required for the methylation
    # call step, in order to output BAM methylation
    # converted for visualization on IGV
    ./winnowmap --MD -t $threads -a -x $preset $ref $barcode.fastq | \
    samtools sort -@ $threads > ${genotype}__${barcode}__${preset}__winnowmap2.bam.tmp

    samtools addreplacerg -r ID:$barcode -r BC:$barcode ${genotype}__${barcode}__${preset}__winnowmap2.bam.tmp |
    samtools view -b > ${genotype}__${barcode}__${preset}__winnowmap2.bam

    samtools index -b ${genotype}__${barcode}__${preset}__winnowmap2.bam
}

# function for merging generated bams
cat_bams () {
    local bams=`ls *__splice__winnowmap2.bam | xargs`
    samtools merge -@ $threads all_libs__splice.bam $bams
    samtools index -b all_libs__splice.bam

    local bams=`ls *__map-ont__winnowmap2.bam | xargs`
    samtools merge -@ $threads all_libs__map-ont.bam $bams
    samtools index -b all_libs__map-ont.bam
}

# function to remove tmp files
rm_tmp_files () {
    rm *tmp
}

# main function
main () {

    # link files and set them up
    set_up_files

    # getting only duplex and simplex reads
    # and converting to fastq
    samtools view -h -d dx:1 -d dx:0 20240520_AL5RACE002.bam |\
    samtools fastq -@ $threads > 20240520_AL5RACE002.fastq

    # setting up libs and genotype
    genotypes=("GRCh38_with_XDP_SVA" "GRCh38_with_XDP_SVA__chrX_71430000-71453000")
    files=("20240520_AL5RACE002")
    presets=("map-ont" "splice")
    # presets=("map-ont")

    # running for each lib
    for i in ${files[@]} ; do
        for j in ${genotypes[@]} ; do    
            for k in ${presets[@]} ; do
                # running aligner
                run_minimap2 $i $j $k
                run_winnowmap2 $i $j $k
            done
        done
    done

    # merging bams
    # cat_bams

    # removing tmp files
    rm_tmp_files

}

# calling main function
main
