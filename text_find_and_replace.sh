#!/bin/bash
set -euo pipefail
# text_find_and_replace.sh
# Copyright Jackson M. Tsuji, 2017
# Neufeld lab, University of Waterloo, Canada
# Created Nov. 18, 2017
# Description: Finds and replaces target names in a file with user-provided names. Works for any text file (e.g., renaming FastA sequence headers, phylogenetic tree file names, and so on.

script_version=1.2.0

# If no input is provided, exit out and provide help
if [ $# == 0 ]; then

	printf "\n$(basename $0): finds and replaces selected text in a file.\n"
	printf "Version: ${script_version}\n"
	printf "Contact Jackson M. Tsuji (jackson.tsuji@uwaterloo.ca) for bug reports or feature requests.\n\n"
	printf "Usage: $(basename $0) text_replacement_info_file.tsv input_file.txt output_file.txt\n\n"
	printf "Usage details:\n* Output file should not exist ahead of time, or else it will be overwritten.\n"
	printf "* text_replacement_file.tsv: tab-separated file with headers. Old names (target) in first column, and new names (replacement) in second column. Case sensitive.\n"
	printf "AVOID special characters (other than whitespace, for which support was added in v1.1.0)\n\n"
   	exit 1

fi

# Get user arguments
TEXT_REPLACEMENT_INFO_FILE=$1
INPUT_FILEPATH=$2
OUTPUT_FILEPATH=$3

function read_input_tsv_file {
	# Description: reads old/new name info from the text replacement info file into memory as bash arrays
	# User-specified parama: TEXT_REPLACEMENT_INFO_FILE
	# Script-generated params: none
	# Return: names_old (array); names_new (array)

	# Temporarily change the internal fields separator (IFS) so that whitespaces in find/replace scheme do not create new entries. See Vince Buffalo's "Bioinformatics Data Skills" (1st Ed.) chapter 12, pg 407 and corresponding Github page README at https://github.com/vsbuffalo/bds-files/tree/master/chapter-12-pipelines (accessed Nov 19, 2017)
	OFS="$IFS"
	IFS=$'\n'

	# Get lists of old and new filenames and store as arrays
	names_old=($(tail -n +2 "${TEXT_REPLACEMENT_INFO_FILE}" | cut -d $'\t' -f 1))
	names_new=($(tail -n +2 "${TEXT_REPLACEMENT_INFO_FILE}" | cut -d $'\t' -f 2))
	# Got help from http://stackoverflow.com/questions/2961673/find-missing-argument-to-exec, post by Marian on June 2, 2010; accessed May 13, 2016

	# Fix the IFS
	IFS="$OFS"

	# Confirm number of names is equal between lists
	if [ ${#names_old[@]} != ${#names_new[@]} ]; then

		printf "Error: ${#names_old[@]} entries in old names column and ${#names_new[@]} in new names column. These do not match. This could possibly be due to special characers in one of the columns, which this has limited support for. Exiting...\n"
		exit 1

	else

		printf "Identified ${#names_old[@]} items for replacement.\n\n"

	fi

}

function run_sed {
	# Description: runs text replacement via sed for all entries in the provided text replacement info file
	# User-specified params: INPUT_FILEPATH; OUTPUT_FILEPATH
	# Script-generated params: names_old (array); names_new (array)
	# Return: saves outfile file to OUTPUT_FILEPATH

	# Make a copy of the tree file for multiple in-place edits
	cp "${INPUT_FILEPATH}" "${OUTPUT_FILEPATH}"

	for i in $(seq 1 ${num_names}); do

		# Set counter to start from zero
		j=$((${i}-1))

		# Get names for this entry and report to user
		old_name="${names_old[${j}]}"
		new_name="${names_new[${j}]}"
		printf "${old_name} --> ${new_name}\n"

		# Run the replacement
		sed -i -e "s/${old_name}/${new_name}/g" $OUTPUT_FILEPATH
		# sed help from http://unix.stackexchange.com/a/159369 (main) and http://stackoverflow.com/a/15236526 (debugging), accessed Feb. 22, 2017

	done

	# Remove backup file created by sed once done
	rm ${OUTPUT_FILEPATH}-e

}

function main {

	printf "Running $(basename $0), version $script_version.\n"
	printf "Replacing items in file $(basename ${INPUT_FILEPATH}), based on the list provided in $(basename ${TEXT_REPLACEMENT_INFO_FILE}).\n"

	read_input_tsv_file

	run_sed

	printf "\nReplacing finished. Output saved as $(basename ${OUTPUT_FILEPATH}).\n\n"
	printf "$(basename $0): finished.\n\n"

}

# TODO - make this statement more robust
main

