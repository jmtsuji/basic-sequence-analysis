#!/bin/bash
# fasta_dealign.sh
# Copyright Jackson M. Tsuji, 2017
# Neufeld lab, University of Waterloo, Canada
# Created Nov. 18, 2017
# Description: De-aligns input multi-FastA file.

# Sources:
#   General awk help: http://www.grymoire.com/Unix/Awk.html#uh-0 (May 13, 2015, and June 1, 2015)
#   Based off code sent to me by Michael Hall on June 17, 2013 via email.

# Basic script stuff (from Vince Buffalo's "Bioinformatics Data Skills" (1st Ed.) chapter 12, pg 397):
set -e
set -u
set -o pipefail

script_version=1.0.0

# If input field is empty, give error message and end script
if [ $# == 0 ]
then
printf "$(basename $0): de-aligns multi-FastA file.\nVersion: ${script_version}\nContact Jackson M. Tsuji (jackson.tsuji@uwaterloo.ca) for bug reports or feature requests.\n\nUsage: $(basename $0) input_aligned.fasta > output_dealigned.fasta\n\n*Note: all this script does is remove dashes in sequences (non-header) sections.\n"
exit 1
fi
# Using printf: http://stackoverflow.com/a/8467449 (accessed Feb 21, 2017)
# Test for empty variable: Bioinformatics Data Skills Ch. 12 pg 403-404, and http://www.tldp.org/LDP/Bash-Beginners-Guide/html/sect_09_07.html and http://stackoverflow.com/a/2428006 (both accessed Feb 21, 2017)

# Read input file name from user input into the script
input=$1
# will output to STDOUT

awk '{ if ($0 !~ /^>/) { \
        gsub("-", ""); \
    } \
print \
} \
' \
$input
