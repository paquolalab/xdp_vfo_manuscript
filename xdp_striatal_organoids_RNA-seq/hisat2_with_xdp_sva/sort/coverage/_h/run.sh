#!/bin/bash
set -o errexit -o pipefail

# alorenzetti 20250113
# description ####
# this script will link
# necessary bam files
# and compute coverage
# for a subset of reads
# having a proper pair
# and with a proper mapping qual

# setting up ####
# getting started ####
threads=8

# initializing conda 
eval "$(conda shell.bash hook)"

# activating required env
conda activate misc_env

# getting started ####
# linking files
link_files () {

    # linking bam files
    ln -s ../../_m/*.bam .
    ln -s ../../_m/*.bam.bai .

    # linking metadata
    ln -s ../../../../analysis_speaqeasy/metadata/metadata_formated_for_manuscript/_m/xdp_bulkrnaseq_metadata.tsv .

}

# ordering samples from metadata
order_samples () {

    # ordering samples
    tail -n +2 xdp_bulkrnaseq_metadata.tsv | \
    sort -k4,4r -k6,6n | \
    awk -v FS="\t" -v OFS="\t" \
    '{{print $2,$2"__"$4"__"$3"__"$6}}' > ordered_samples.txt

}

# computing coverage
run_bamCoverage () {
    local file=$1
    local file_prefix=$2
    local half_threads=$(( threads / 2 ))    
    
    # bedgraph out format
    # include only properly paired reads flag=2
    # exclude reads with flag=2304 (256 + 2048, not primary and supplementary alignments)
    # CPM normalization will use the total number of mapped reads in the BAM file
    # after the include/exclude filters are applied
    bamCoverage -p $half_threads \
                --bam $file \
                --minMappingQuality 60 \
                --samFlagInclude 2 \
                --samFlagExclude 2304 \
                --normalizeUsing CPM \
                -o ${file_prefix}__fwd.bedgraph \
                -of bedgraph \
                -bs 1 \
                --filterRNAstrand=forward \
                --region chrX:71300000:71600000 \
                > ${file_prefix}__fwd__bg_out.log \
                2> ${file_prefix}__fwd__bg_err.log &
    
    bamCoverage -p $half_threads \
                --bam $file \
                --minMappingQuality 60 \
                --samFlagInclude 2 \
                --samFlagExclude 2304 \
                --normalizeUsing CPM \
                -o ${file_prefix}__rev.bedgraph \
                -of bedgraph \
                -bs 1 \
                --filterRNAstrand=reverse \
                --region chrX:71300000:71600000 \
                > ${file_prefix}__rev__bg_out.log \
                2> ${file_prefix}__rev__bg_err.log &

    # Wait for both jobs to finish
    wait
    
}

# function to expand bedgraph coverage to per-base coordinates
expand_bedgraph () {
    local bedgraph_file=$1
    local expanded_file="${bedgraph_file/.bedgraph/_expanded.bedgraph}"
    
    # Process bedgraph file to expand windows to individual bases
    # Each line in output will have: chrom, pos, pos+1, coverage
    awk '{
        for(i=$2; i<$3; i++) {
            print $1"\t"i"\t"(i+1)"\t"$4
        }
    }' "$bedgraph_file" > "$expanded_file"
}

# main function
main () {
    
    # linking files
    link_files

    # ordering samples
    order_samples

    # computing coverage
    while IFS=$'\t' read sample file_prefix ; do
        run_bamCoverage ${sample}.bam $file_prefix
    done < ordered_samples.txt

    # expanding bedgraph files
    for i in *.bedgraph; do
        expand_bedgraph "$i"
    done

}

# calling main function
main
