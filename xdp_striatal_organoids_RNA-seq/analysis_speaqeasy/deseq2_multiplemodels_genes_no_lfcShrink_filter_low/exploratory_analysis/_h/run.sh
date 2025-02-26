#!/bin/bash
set -o errexit -o pipefail

# alorenzetti 20250105
# description ####
# this script will call
# a jupyter notebook

# setting up ####
# getting started ####
threads=20

# initializing conda 
# eval "$(conda shell.bash hook)"

# activating required env
# conda activate pb_env

# getting started ####
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

    call_jupynb main
    
}

# calling main function
main