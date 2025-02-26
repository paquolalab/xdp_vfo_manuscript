#!/usr/bin/env python
"""
Extracts all alignments from read pairs that have at least one mate aligning
to the XPD SVA coordinates: chrX:71440513-71443140
"""

import sys
import argparse
import itertools

import pysam
from tqdm import tqdm

__author__ = 'Apuã Paquola'


def process_sam(input_file, output_file):
    if input_file == '-':
        fp = sys.stdin
    else:
        fp = input_file

    with pysam.AlignmentFile(fp, 'r') as infile:
        with pysam.AlignmentFile(output_file, 'wb', header=infile.header) as outfile:
            for k,g in tqdm(itertools.groupby(infile, key=lambda x: x.query_name)):

                # Output all alignments of read pair if at least one mate overlaps XDP SVA
                l = list(g)
                if any(not read.is_unmapped and read.reference_name == 'chrX' and read.get_overlap(71440513, 71443140) > 0 for read in l):
                    for read in l:
                        outfile.write(read)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('-i', '--input')
    parser.add_argument('-o', '--output')
    args=parser.parse_args()

    process_sam(args.input, args.output)

    
if __name__ == '__main__':
    main()

