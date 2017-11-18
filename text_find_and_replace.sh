#!/bin/bash
# text_find_and_replace.sh
# Copyright Jackson M. Tsuji, 2017
# Neufeld lab, University of Waterloo, Canada
# Created Nov. 18, 2017
# Description: Finds and replaces target names in a file with user-provided names. Works for any text file (e.g., renaming FastA sequence headers, phylogenetic tree file names, and so on.

# Basic script stuff (from Vince Buffalo's "Bioinformatics Data Skills" (1st Ed.) chapter 12, pg 397):
set -e
set -u
set -o pipefail

script_version=1.0.0

# If no input is provided, exit out and provide help
if [ $# == 0 ]
    then
    printf "\n\n$(basename $0): finds and replaces selected text in a file.\nVersion: ${script_version}\nContact Jackson M. Tsuji (jackson.tsuji@uwaterloo.ca) for bug reports or feature requests.\n\nUsage: $(basename $0) text_replacement_file.tsv input_file.txt output_file.txt\n\nUsage details:\n**Output file should not exist ahead of time, or else it will be overwritten.\ntext_replacement_file.tsv: tab-separated file with headers. Old names (target) in first column, and new names (replacement) in second column. Case sensitive.\n\n"
    exit 1
fi
# Using printf: http://stackoverflow.com/a/8467449 (accessed Feb 21, 2017)
# Test for empty variable: Bioinformatics Data Skills Ch. 12 pg 403-404, and http://www.tldp.org/LDP/Bash-Beginners-Guide/html/sect_09_07.html and http://stackoverflow.com/a/2428006 (both accessed Feb 21, 2017)


# set variables from user input:
replacement_info=$1
input_name=$3
output_name=$4

# By default, set working directory to present working directory (pwd)
work_dir=$(pwd)

echo "Running $(basename $0), version $script_version."
echo ""
echo "Replacing items in file $(basename ${input_name}), based on the list provided in $(basename ${replacement_info})."


cd "${work_dir}"

# Get lists of old and new filenames and store as arrays
names_old=($(tail -n +2 $replacement_info | cut -d $'\t' -f 1))
names_new=($(tail -n +2 $replacement_info | cut -d $'\t' -f 2))
# Got help from http://stackoverflow.com/questions/2961673/find-missing-argument-to-exec, post by Marian on June 2, 2010; accessed May 13, 2016

# Get number of names
num_names=${#names_old[@]}

# Confirm number of names is equal between lists
if [ ${#names_old[@]} != ${#names_new[@]} ]
then
    echo "Error: ${#names_old[@]} entires in old names file and ${#names_new[@]} in new names file. These do not match. This could possibly be due to white spaces in one of the files, which this program does not support. Exiting..."
    exit 1
else echo "Identified ${num_names} items for replacement."
fi

echo ""

# Make a copy of the tree file for multiple in-place edits
cp $input_name $output_name

for i in $(seq 1 ${num_names})
do
# Get names
    old_name=${names_old[i-1]}
    new_name=${names_new[i-1]}
    echo "${old_name} --> ${new_name}"
    sed -i -e "s/${old_name}/${new_name}/g" $output_name
done
# "for" loop idea from Bioinformatics Data Skills (Vince Buffalo), Ch. 12
# sed help from http://unix.stackexchange.com/a/159369 (main) and http://stackoverflow.com/a/15236526 (debugging), accessed Feb. 22, 2017

# Remove backup file created by sed once done
rm ${output_name}-e


echo ""
echo "Replacing finished. Output saved as $(basename ${output_name})."
echo ""
echo ""

echo "$(basename $0): finished."
echo ""
