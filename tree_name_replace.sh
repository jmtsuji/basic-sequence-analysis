#!/bin/bash
# Created Feb 22, 2017, by Jackson Tsuji (Neufeld lab PhD student)
# Description: Finds and replaces names in tree file with simpler names. Could actually use this to find and replace names in any kind of text file you'd like. See "00 ABOUT Comamonadacaea metabolic prediction round2.txt" for usage context.
# Last updated: Feb 22, 2017

# Basic script stuff (from Vince Buffalo's "Bioinformatics Data Skills" (1st Ed.) chapter 12, pg 397):
set -e
set -u
set -o pipefail

script_version=1.1.0

# If no input is provided, exit out and provide help
if [ $# == 0 ]
    then
    printf "\n    $(basename $0): finds and replaces selected text in a file.\n\n    Usage: $(basename $0) old_names.list new_names.list input_file.txt output_file.txt \n\n    **Notes: Output file should not exist ahead of time, or else it will be overwritten.\n             Also, old and new name lists should be in the same order and contain the same number of entires.\n\n"
    exit 1
fi
# Using printf: http://stackoverflow.com/a/8467449 (accessed Feb 21, 2017)
# Test for empty variable: Bioinformatics Data Skills Ch. 12 pg 403-404, and http://www.tldp.org/LDP/Bash-Beginners-Guide/html/sect_09_07.html and http://stackoverflow.com/a/2428006 (both accessed Feb 21, 2017)


# set variables from user input:
old_names=$1
new_names=$2
treefile_name=$3
output_treefile_name=$4

# By default, set working directory to present working directory (pwd)
work_dir=$(pwd)

echo "Running $(basename $0), version $script_version."
echo "Will replace old names in tree file with new names provided in list."
echo ""

cd "${work_dir}"

# Get lists of old and new filenames and store as arrays
# Note: name will be stored without extension (suffix) for simplicity later on
names_old=($(cut -f 1 ${old_names}))
names_new=($(cut -f 1 ${new_names}))
# Got help from http://stackoverflow.com/questions/2961673/find-missing-argument-to-exec, post by Marian on June 2, 2010; accessed May 13, 2016

# Get number of names
num_names=${#names_old[@]}

# Confirm number of names is equal between lists
if [ ${#names_old[@]} != ${#names_new[@]} ]
then
    echo "Error: ${#names_old[@]} entires in old names file and ${#names_new[@]} in new names file. These do not match. This could possibly be due to white spaces in one of the files, which this program does not support. Exiting program."
    exit 1
else echo "Identified ${num_names} sequence IDs for replacement. Same number in both input files - good."
fi

echo ""

# Replace in a loop
echo "Replacing old names in file ${treefile_name}, based on the list provided in ${old_names}, with new names provided in the list ${new_names}. Assumes the two name lists are in the same order."
echo ""

# Make a copy of the tree file for multiple in-place edits
cp $treefile_name $output_treefile_name

for i in $(seq 1 ${num_names})
do
# Get names
    old_name=${names_old[i-1]}
    new_name=${names_new[i-1]}
    echo "Replacing ${old_name} with ${new_name}"
    sed -i -e "s/${old_name}/${new_name}/g" $output_treefile_name
done
# "for" loop idea from Bioinformatics Data Skills (Vince Buffalo), Ch. 12
# sed help from http://unix.stackexchange.com/a/159369 (main) and http://stackoverflow.com/a/15236526 (debugging), accessed Feb. 22, 2017

echo ""
echo "Replacing finished. New tree file saved as ${output_treefile_name}. Backup file (${output_treefile_name}-e) can be deleted."
echo ""
echo ""

echo "$(basename $0): finished."
echo ""
