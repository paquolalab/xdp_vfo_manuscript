#!/bin/bash
set -o errexit -o pipefail

# alorenzetti 20240520
# description ####
# this script will convert fast5
# files to POD5 format

# setting up ####
threads=14

# getting started ####
# setting up reference files
link_files () {

    # getting pod5 files
    ln -s ../../../raw_data/_m/35833A_d120/20240520_1321_MN23086_ATD849_168bee35/pod5/ .

}

# main function
main () {

    # link files
    link_files

    # pod5 conversion
    # if [[ ! -d pod5 ]] ; then mkdir pod5 ; fi
    # pod5 convert fast5 *.fast5 --threads $threads --output pod5/

    # splitting pod5 for increased duplex base call speed
    pod5 view pod5/ --include "read_id, channel" --output summary.tsv
    pod5 subset pod5/ --summary summary.tsv --columns channel --output split_by_channel

}

# calling main function
main
