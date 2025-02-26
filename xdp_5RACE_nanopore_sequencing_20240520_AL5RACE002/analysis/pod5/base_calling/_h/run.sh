#!/bin/bash
set -o errexit -o pipefail

# alorenzetti 20240520
# description ####
# this script will base call
# reads using dorado

# setting up ####
threads=10

# getting started ####
# setting up reference files
link_files () {

    # getting pod5 file
    ln -s ../../_m/split_by_channel .

}

# main function
main () {

    # link files
    link_files

    # base call using 
    # the most accurate model sup
    # according to this issue, chimeric read splitting will be handled
    # https://github.com/nanoporetech/dorado/issues/510
    /opt/dorado-0.6.1-linux-x64/bin/dorado duplex sup split_by_channel > base_called.bam
    
    # getting a summary of base calling
    /opt/dorado-0.6.1-linux-x64/bin/dorado summary base_called.bam > base_called__summary.tsv

}

# calling main function
main
