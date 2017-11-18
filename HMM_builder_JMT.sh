#!/bin/bash
# Created Jan 18, 2017, by Jackson Tsuji (Neufeld lab PhD student)
# Description: builds Hidden Markov Models (HMMs) from unaligned protein sequence input files (FastA format)
#               Run this script within the folder that contains the protein files. Will run for all FastA files.
# Last updated: Jan 18, 2017

# Basic script stuff (from Vince Buffalo's "Bioinformatics Data Skills" (1st Ed.) chapter 12, pg 397):
set -e
set -u
set -o pipefail

script_version=1.0.1

# Manually set thread setting:
num_threads=4

echo "Running $(basename $0), version $script_version."
echo "Will align and build HMMs from all FastA files in the current directory. Assumes FastA files contain protein data."
echo ""

# Make output directory for aligned files
mkdir -p "align"
mkdir -p "hmm"

# Get list of FastA files in current directory (store as an array for looping)
# Note: name will be stored without ".fasta" suffix for simplicity later on
filename_base=($(find -maxdepth 1 -name "*.fasta" -type f -exec basename {} .fasta \;))
# Got help from http://stackoverflow.com/questions/2961673/find-missing-argument-to-exec, post by Marian on June 2, 2010; accessed May 13, 2016
echo "Identified ${#filename_base[@]} FastA files to build HMMs from."
echo ""

# Aligning sequence files
echo "Aligning sequence files using Clustal-Omega version $(clustalo --version)"
echo ""

for name in ${filename_base[@]}
do
    echo "Aligning ${name}.fasta"
clustalo -i "${name}.fasta" -t Protein --threads=${num_threads} -v --log "align/${name}_aln.log" > "align/${name}_aligned.fasta"
done
# "for" loop idea from Bioinformatics Data Skills (Vince Buffalo), Ch. 12

echo ""
echo "Alignment finished."
echo ""
echo ""


# Building HMMs
echo "Building HMMs using hmmbuild from HMMER version $(hmmbuild -h 2>&1 | head -n 2 | tail -n 1 | cut -f 3 -d ' ')"
echo ""

for name in ${filename_base[@]}
do
    echo "Building HMM for ${name}.fasta"
    hmmbuild --amino -o "hmm/${name}_hmmbuild.log" -O "hmm/${name}_annotated.fasta" "hmm/${name}.hmm" "align/${name}_aligned.fasta"
done

echo ""
echo "Finished building HMMs."
echo ""
echo ""

echo "$(basename $0): finished."
echo ""
