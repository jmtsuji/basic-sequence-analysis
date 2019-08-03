#!/usr/bin/env bash
set -euo pipefail

# seq_name_simplify.sh
# Copyright Jackson M. Tsuji, Neufeld Research Group, 2019
# Description: simplifies sequence names in FastA files to make them more suitable for bioinformatics analyses
# Credits: Based off template code from Michael Hall, a former bioinformatician in our group

# Startup processes
VERSION=$(basic-sequence-analysis-version)
script_name=${0##*/}
script_name=${script_name%.*}

# If incorrect input is provided, provide help and exit
if [ $# != 1 ]; then
	printf "Error: missing or extra arguments supplied. To see help statement, run ${0##*/} -h\n"
    exit 1
fi
if [ $1 = "-h" -o $1 = "--help" ]; then
    # Help statement
	printf "${script_name}: simplifies sequence names in FastA files to make them more suitable for bioinformatics analyses.\n"
	printf "Version: ${VERSION}\n"
	printf "Copyright Jackson M. Tsuji, Neufeld Research Group, 2019\n"
	printf "Contact Jackson M. Tsuji (jackson.tsuji@uwaterloo.ca) for bug reports or feature requests.\n"
	printf "Dependencies: seqtk\n\n"
	printf "Usage: ${0##*/} input.fasta > output.fasta\n\n"
	printf "Usage details:\n"
	printf "   - All this script does is perform a gsub find/replace of special characters in FastA headers (and changes dots to dashed in sequence names).\n"
	printf "   - Input FastA files can be gzipped or unzipped. STDOUT output will be unzipped.\n"
	printf "   - To receive from STDIN use '-' as the input.fasta entry\n\n"

	# Exit
	exit 1
fi

# Receive user input
input=$1

seqtk seq -A ${input} | \
awk '{ \
    if ($0 ~ /^>/) { \
        gsub("[^A-Za-z0-9>]", "_"); \
    } \
    else { \
        gsub(/\./, "-"); \
    } \
print \
}'
