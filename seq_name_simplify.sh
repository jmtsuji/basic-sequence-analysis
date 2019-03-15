#!/usr/bin/env bash
set -euo pipefail

# seq_name_simplify.sh
# Copyright Jackson M. Tsuji, Neufeld Research Group, 2019
# Description: simplifies sequence names in FastA files to make them more suitable for bioinformatics analyses

VERSION=$(basic-sequence-analysis-version)

# If no input is provided, provide help and exit
if [ $# -lt 1 ]; then
	# Assign script name
	script_name=${0##*/}
	script_name=${script_name%.*}

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

# Sources:
#   General awk help: http://www.grymoire.com/Unix/Awk.html#uh-0 (May 13, 2015, and June 1, 2015)
#   Read function: http://tldp.org/LDP/Bash-Beginners-Guide/html/sect_08_02.html (May 13, 2015)
#   Wildcard regex: http://www.panix.com/~elflord/unix/grep.html#wildcards (June 1, 2015)
#   Based off code sent to me by Michael Hall on June 17, 2013 via email.

# Test if the user wishes to receive from STDIN
if [ $1 == "-" ]; then
    input="-" # This means to receive from STDIN
else
    # Read input file name from user input into the script
    input=$2
fi

seqtk seq -A ${input} \
awk '{ \
    if ($0 ~ /^>/) { \
        gsub("[^A-Za-z0-9>]", "_"); \
    } \
    else { \
        gsub(/\./, "-"); \
    } \
print \
} '

