#!/bin/bash
# Created March 13, 2017, by Jackson Tsuji (Neufeld lab PhD student)
# Description: Generates length report of FastA files
# Last updated: March 13, 2017

# Basic script stuff (from Vince Buffalo's "Bioinformatics Data Skills" (1st Ed.) chapter 12, pg 397):
set -e
set -u
set -o pipefail

script_version=1.0.0
#date_code=$(date '+%y%m%d')

## If input field is empty, print help and end script
#if [ $# == 0 ]
#then
#printf "    $(basename $0) version ${script_version}: Get lengths of FastA files.\n    Contact Jackson Tsuji (jackson.tsuji@uwaterloo.ca; Neufeld research group) for error reports or feature requests.\n\n    Usage: $(basename $0) > lengths_list.txt \n\n    ***Requirements:\n        Runs in current directory.\n        All files should have the suffix '.fa', '.fst', or '.fasta'.\n        Files can be in subfolders within the directory when you run the script.\n\n"
#exit 1
#fi
## Using printf: http://stackoverflow.com/a/8467449 (accessed Feb 21, 2017)
## Test for empty variable: Bioinformatics Data Skills Ch. 12 pg 403-404, and http://www.tldp.org/LDP/Bash-Beginners-Guide/html/sect_09_07.html and http://stackoverflow.com/a/2428006 (both accessed Feb 21, 2017)


#################################################################
##### Settings: #################################################
out_dir=$(pwd) # Forces to run in current directory
#################################################################

#echo "Running $(basename $0) version $script_version on ${date_code} (yymmdd)."
#echo ""

#start_time=$(date)

## Make output directory and go there
#mkdir -p $out_dir
#cd $out_dir

# Get list of FastA files (store as an array for looping)
# Note: name will be stored with full file path and extension for simplicity later on
fasta_files=($(find ${out_dir} -type f -name "*.fa" -or -name "*.fst" -or -name "*.fasta"))
# Got help from http://stackoverflow.com/questions/2961673/find-missing-argument-to-exec, post by Marian on June 2, 2010; accessed May 13, 2016
#echo "Found ${#fasta_files[@]} FastA files."

for fasta_file in ${fasta_files[@]}
do
    cd $out_dir
    sample_id=$(basename ${fasta_file})
    #    echo "For sample ${sample_id}:"
    length=$(grep -c "^>" ${fasta_file})
    printf "${sample_id}:\t${length}\n"
done

#end_time=$(date)

#echo ""
#echo ""
#echo "Done."
#echo ""
#
#echo "$(basename $0): finished. Output can be fount in ${out_dir}."
#echo "Started at ${start_time} and finished at ${end_time}."
#echo ""
