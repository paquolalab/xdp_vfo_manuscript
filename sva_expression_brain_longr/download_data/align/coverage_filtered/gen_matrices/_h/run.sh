#!/bin/bash
set -o errexit -o pipefail

# alorenzetti 20220918
# description ####
# this script will create
# matrices of coverage
# for multiple genes (SVAs)

# setting up ####
# running params script
source /ceph/users/alorenzetti/sva_expression_brain_longr/_h/params.sh

# getting started ####
# initializing conda 
eval "$(conda shell.bash hook)"

# getting started ####
# linking bw files
link_files () {

    # bam files and respective indexes
    ln -s ../../_m/*bw .
    # ln -s ../../_m-bckp/*bw .
    
}

# parsing sva file from
# van Bree et al. 2022
# Supplemental_Table_S1
# doi: 10.1101/gr.275515.121
parse_sva () {

    # activating R env
    conda activate $conda_env_name_r
    
    # linking Rscript and
    # original supp table
    ln -s ../_h/Supplemental_Table_S1.xlsx .
    
    # 
    R -q -f ../_h/parse_sva.R --args Supplemental_Table_S1.xlsx
      
    # deactivating R env
    conda deactivate
    
}

# generating coverage matrices
gen_cov_matrices () {
    local sample=$1
    local covtype=$2
    local strand=$3
    local flank=$4
    local orient=$5
    
    if [[ $strand != "forward" && $strand != "reverse" ]] ; then
        echo "Error: Strand argument should be forward or reverse."
        return 1
    fi
    
    if [[ $covtype != "coverage" && $covtype != "5_prime_profile" ]] ; then
        echo "Error: Coverage type argument should be coverage or 5_prime_profile."
        return 1
    fi
    
    if [[ $orient != "sense" && $orient != "antisense" ]] ; then
        echo "Error: Orientation should be sense or antisense."
        return 1
    fi
    
    if [[ $orient == "antisense" ]] ; then
        if [[ $strand == "forward" ]] ; then
            alt_strand="reverse"
        elif [[ $strand == "reverse" ]] ; then
            alt_strand="forward"
        fi
    else
        alt_strand=$strand
    fi
    
    # computing coverage matrix
    computeMatrix reference-point --regionsFileName sva_$strand.bed \
                                  --scoreFileName ${sample}_${covtype}_${alt_strand}.bw \
                                  --outFileName ${sample}_${covtype}_${strand}_${orient}_matrix.txt.gz \
                                  --outFileNameMatrix ${sample}_${covtype}_${strand}_${orient}_matrix.tsv \
                                  --referencePoint TSS \
                                  --beforeRegionStartLength $flank \
                                  --afterRegionStartLength $flank \
                                  --binSize 1 \
                                  --sortRegions keep \
                                  -p $threads
    # plotting heatmap
#     plotHeatmap --matrixFile ${sample}_${covtype}_${strand}_${orient}_matrix.txt.gz \
#                 --outFileName ${sample}_${covtype}_${strand}_${orient}_heatmap.png \
#                 --averageTypeSummaryPlot sum \
#                 --plotType fill \
#                 --dpi 600
                
#     # plotting profile
#     plotProfile --matrixFile ${sample}_${covtype}_${strand}_${orient}_matrix.txt.gz \
#                 --outFileName ${sample}_${covtype}_${strand}_${orient}_profile.png \
#                 --averageType sum \
#                 --plotType fill \
#                 --dpi 600

}

# main function
main () {

    # linking bam files
    link_files
    
    # parsing svas
    parse_sva

    # activating conda env
    conda activate $conda_env_name
    
    # generating cov matrices for samples
    samples=`ls *coverage_forward.bw | sed 's/_coverage_forward.bw//'`
    covtypes=("coverage 5_prime_profile")
    strands=("forward" "reverse")
    orients=("sense" "antisense")
    for i in ${samples[@]} ; do
        for j in ${covtypes[@]}; do
            for k in ${strands[@]}; do
                for l in ${orients[@]} ; do
                    gen_cov_matrices $i $j $k 1000 $l
                done
            done
        done
    done
    
    # deactivating conda env
    conda deactivate
}

# running main function ####
main