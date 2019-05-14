#!/usr/bin/env bash
set -euo pipefail

# fasta_dealign.sh
# Copyright Jackson M. Tsuji, Neufeld Research Group, 2019
# Description: De-aligns input multi-FastA file.

# Startup processes
VERSION=$(basic-sequence-analysis-version)
script_name=${0##*/}
script_name=${script_name%.*}

# If no input is provided, provide help and exit
if [ $# -lt 1 ]; then

	# Help statement
	printf "${script_name}: de-aligns input multi-FastA file.\n"
	printf "Version: ${VERSION}\n"
	printf "Copyright Jackson M. Tsuji, Neufeld Research Group, 2019\n"
	printf "Contact Jackson M. Tsuji (jackson.tsuji@uwaterloo.ca) for bug reports or feature requests.\n"
	printf "Dependencies: seqtk\n\n"
	printf "Usage: ${0##*/} input_aligned.fasta > output_dealigned.fasta\n\n"
	printf "Usage details:\n"
	printf "   - All this script does is remove dashes or dots in sequence (non-header) sections.\n"
	printf "   - To receive from STDIN, use '-' as the input_aligned.fasta entry\n\n"

	# Exit
	exit 1
fi

# Test if the user wishes to receive from STDIN
if [ $1 == "-" ]; then
    input_filepath="-" # This means to receive from STDIN
else
    # Read input file name from user input into the script
    input_filepath=$1
fi

seqtk seq -A ${input_filepath} | \
awk '{ if ($0 !~ /^>/) { \
        gsub(/-|\./, ""); \
    } \
print \
} '

# will output to STDOUT

