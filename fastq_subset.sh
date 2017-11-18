#!/bin/bash
# Created Jan 18, 2017, by Jackson Tsuji (Neufeld lab PhD student)
# Description: builds Hidden Markov Models (HMMs) from unaligned protein sequence input files (FastA format)
#               Run this script within the folder that contains the protein files. Will run for all FastA files.
# Last updated: March 28, 2017

# Basic script stuff (from Vince Buffalo's "Bioinformatics Data Skills" (1st Ed.) chapter 12, pg 397):
set -e
set -u
set -o pipefail

script_version=1.0.0
date_code=$(date '+%y%m%d')

# If input field is empty, print help and end script
if [ $# == 0 ]
then
printf "    $(basename $0) version ${script_version}: subsamples all samples in specified folder to desired read number/fraction. Saves output to current directory. \n    Contact Jackson Tsuji (jackson.tsuji@uwaterloo.ca; Neufeld research group) for error reports or feature requests.\n\n    Usage: $(basename $0) path/to/files subset_size SEED 2>&1 | tee $(basename $0 .sh).log \n\n    ***Requirements:\n        Input metagenome files should be in gzipped FastQ format, i.e. with .fastq.gz extension, and not be in subfolders.\n\n    Note that your output will be saved to the folder where you run this script.\n\n"
exit 1
fi
# Using printf: http://stackoverflow.com/a/8467449 (accessed Feb 21, 2017)
# Test for empty variable: Bioinformatics Data Skills Ch. 12 pg 403-404, and http://www.tldp.org/LDP/Bash-Beginners-Guide/html/sect_09_07.html and http://stackoverflow.com/a/2428006 (both accessed Feb 21, 2017)

start_time=$(date)

#################################################################
##### Settings: #################################################
out_dir=$(pwd) # means you have to run the script in this folder.
files_location=$1
subset_size=$2
seed=$3
#################################################################

echo "Running $(basename $0), version $script_version."
echo "Will subset sequences from all gzipped FastQ files in the current directory. Will use same specified SEED setting for each so that the same subset will be taken for paired-end files."
echo ""

cd $out_dir

# Make output sub-directory
mkdir -p "head"

cd $files_location

# Get list of gzipped FastQ files in current directory (store as an array for looping)
# Note: name will be stored without extension (suffix) for simplicity later on
filename_base=($(find -maxdepth 1 -name "*.fastq.gz" -type f -exec basename {} .fastq.gz \;))
# Got help from http://stackoverflow.com/questions/2961673/find-missing-argument-to-exec, post by Marian on June 2, 2010; accessed May 13, 2016
echo "Identified ${#filename_base[@]} gzipped FastQ files."
echo ""

cd $out_dir

# Subsetting sequence files
echo "Subsetting ${subset_size} sequences from each file using seqtk $(seqtk 2>&1 | head -n 3 | tail -n 1) with SEED value of ${seed}"
echo ""

echo "Subsetting files:"

for name in ${filename_base[@]}
do
    echo "${name}.fastq.gz"
    seqtk sample -2 -s ${seed} "${files_location}/${name}.fastq.gz" ${subset_size} > "${name}_subset.fastq"
    head -n 16 "${name}_subset.fastq" > head/"${name}_subset_head.txt"
    gzip "${name}_subset.fastq"
done
# "for" loop idea from Bioinformatics Data Skills (Vince Buffalo), Ch. 12

echo ""
echo ""
echo ""

end_time=$(date)

echo "$(basename $0): finished. Output can be fount in ${out_dir}."
echo "Started at ${start_time} and finished at ${end_time}."
echo ""
