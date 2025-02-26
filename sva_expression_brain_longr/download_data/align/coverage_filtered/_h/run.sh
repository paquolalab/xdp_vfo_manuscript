#!/bin/bash
set -o errexit -o pipefail

# alorenzetti 20220926
# description ####
# this script will create
# coverage tracks
# for each sample using
# the unfiltered bam files

# requires samtools >= 1.14
# to use the filter based
# on read names (-N)

# setting up ####
# running params script
source /ceph/users/alorenzetti/sva_expression_brain_longr/_h/params.sh

# getting started ####
# initializing conda 
eval "$(conda shell.bash hook)"

# getting started ####
# linking bam files
link_files () {

    # bam files and respective indexes
    ln -s ../../../_m/bam_unfiltered/*_sorted.bam* .
    
}

# getting number of alignments
# per bam file
get_nreads () {

    local bamfile=$1
    sample=${bamfile/_sorted.bam}
    
    # removing unaligned reads and
    # supplementary reads; the existence
    # of supplementary reads is contingent
    # on the existence of a primary read
    # so the true number of aligned reads 
    # should not account for them
    nreads=`samtools view -F 0x800 -F 0x4 $bamfile | wc -l`
    
    echo -e "$sample\t$nreads"
    
}

# parsing sva file from
# van Bree et al. 2022
# Supplemental_Table_S1
# doi: 10.1101/gr.275515.121
parse_sva () {

    local flankleft=$1
    local flankright=$2
    
    # activating R env
    conda activate $conda_env_name_r
    
    # linking Rscript and
    # original supp table
    ln -s ../_h/Supplemental_Table_S1.xlsx .
    
    # running parser
    R -q -f ../_h/parse_sva.R --args Supplemental_Table_S1.xlsx
    
    # creating an alt version with flanking regions
    awk -v lf=$flankleft -v rf=$flankright -v OFS="\t" -v FS="\t" '{if($6 == "+"){print $1,$2-lf,$2+rf,$1":"$2-lf":"$2+rf,$5,$6}; if($6 == "-"){print $1,$3-rf,$3+lf,$1":"$3-rf":"$3+lf,$5,$6}}' sva.bed > sva_starts_w_flanks.bed
    
    # deactivating R env
    conda deactivate
    
}

# getting names using an R script
get_read_names () {

    local bamfile=$1
    local region_file=$2
    
    # activating R env
    conda activate $conda_env_name_r
    
    # running script
    R -f ../_h/find_rnames.R --args $bamfile $region_file
    
    # deactivating R env
    conda deactivate

}

# filtering bam files
filter_bam () {

    local sample=$1
    
    samtools view -h -N ${sample}_readnames.txt ${sample}_sorted.bam | \
    samtools sort > ${sample}_sorted_filtered.bam
    samtools index -b ${sample}_sorted_filtered.bam

}

# generating complete
# or five prime profile
# for reads (fwd or rev)
gen_cov () {
    local bam=$1
    local covtype=$2
    local strand=$3
    
    sample_name=${bam/_sorted_filtered.bam/}
    
    if [[ $strand != "forward" && $strand != "reverse" ]] ; then
        echo "Error: Strand argument should be forward or reverse."
        return 1
    fi
    
    if [[ $strand == "forward" ]] ; then
        opostrand="reverse"
    else
        opostrand="forward"
    fi
    
    if [[ $covtype != "coverage" && $covtype != "5_prime_profile" ]] ; then
        echo "Error: Coverage type argument should be coverage or 5_prime_profile."
        return 1
    fi
    
    if [[ $covtype == "5_prime_profile" ]] ; then
        offset="--Offset 1"
    else
        offset=" "
    fi
    
    
    # warning: deeptools assumes
    # strandness is given using the
    # dUTP standard, so we gotta invert
    # it ourselves
    bamCoverage --bam $bam \
                --filterRNAstrand=$strand \
                --binSize 1 \
                $offset \
                -p $threads \
                --skipNonCoveredRegions \
                --outFileFormat bigwig \
                --outFileName ${sample_name}_${covtype}_${opostrand}.bw

}

# main function
main () {

    # linking bam files
    link_files
    
    # parsing sva supp
    # and adding flanking
    # regions to start sites
    # for the filtering step
    parse_sva 1000 1000
    
    # activating conda env
    conda activate $conda_env_name

    # generating coverage for samples
    covtypes=("coverage 5_prime_profile")
    strands=("forward" "reverse")
    for i in *_sorted.bam ; do
    # for i in ENCFF011XVU_sorted.bam ; do
        sample=${i/_sorted.bam}
        
        # getting nalignments per bam
        get_nreads $i >> n_reads_per_bam.tsv
        
        # getting read names to filter
        get_read_names $i sva_starts_w_flanks.bed
        
        # filtering bams
        filter_bam $sample
    
        for j in ${covtypes[@]}; do
            for k in ${strands[@]}; do
                gen_cov ${sample}_sorted_filtered.bam $j $k
            done
        done
    done
    
    # deactivating conda env
    conda deactivate
}

# running main function ####
main
