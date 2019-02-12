#!/bin/bash
# fasta_dealign.sh
# Copyright Jackson M. Tsuji, 2017
# Neufeld lab, University of Waterloo, Canada
# Created Nov. 18, 2017
# Description: De-aligns input multi-FastA file.

# Sources:
#   General awk help: http://www.grymoire.com/Unix/Awk.html#uh-0 (May 13, 2015, and June 1, 2015)
#   Based off code sent to me by Michael Hall on June 17, 2013 via email.
#   Receiving from STDIN: https://superuser.com/a/747905 (accessed Nov. 18, 2017)

# Basic script stuff (from Vince Buffalo's "Bioinformatics Data Skills" (1st Ed.) chapter 12, pg 397):
set -e
set -u
set -o pipefail

script_version=1.1.0

# If input field is empty, give error message and end script
if [ $# == 0 ]; then
printf "$(basename $0): de-aligns multi-FastA file.\nVersion: ${script_version}\nContact Jackson M. Tsuji (jackson.tsuji@uwaterloo.ca) for bug reports or feature requests.\n\nUsage: $(basename $0) input_aligned.fasta > output_dealigned.fasta\n\n*Notes:\n\tAll this script does is remove dashes in sequences (non-header) sections.\n\n\t**This script CANNOT support wrapped FastA files. If they are wrapped (sequence info has line breaks), you have to unwrap them ahead of time, e.g., using the seqtk package: seqtk seq -A input_aligned.fasta | $(basename $0) - > output_dealigned.fasta\n\n\tTo receive from STDIN, run as $(basename $0) - > output_dealigned.fasta\n\n"
exit 1
fi
# Using printf: http://stackoverflow.com/a/8467449 (accessed Feb 21, 2017)
# Test for empty variable: Bioinformatics Data Skills Ch. 12 pg 403-404, and http://www.tldp.org/LDP/Bash-Beginners-Guide/html/sect_09_07.html and http://stackoverflow.com/a/2428006 (both accessed Feb 21, 2017)

# Test if the user wishes to receive from STDIN
if [ $1 == "-" ]; then
    input="-" # This means to receive from STDIN
else
    # Read input file name from user input into the script
    input=$1
fi

awk '{ if ($0 !~ /^>/) { \
        gsub(/-|\./, ""); \
    } \
print \
} \
' \
$input

# will output to STDOUT
