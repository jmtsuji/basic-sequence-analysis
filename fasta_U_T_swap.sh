#!/bin/bash
# fasta_U_T_swap.sh
# Copyright Jackson M. Tsuji, 2017
# Neufeld lab, University of Waterloo, Canada
# Created Nov. 18, 2017
# Description: Switches between DNA and RNA (U's and T's)

# Sources:
#   General awk help: http://www.grymoire.com/Unix/Awk.html#uh-0 (May 13, 2015, and June 1, 2015)
#   Based off code sent to me by Michael Hall on June 17, 2013 via email.

# Basic script stuff (from Vince Buffalo's "Bioinformatics Data Skills" (1st Ed.) chapter 12, pg 397):
set -e
set -u
set -o pipefail

script_version=1.0.0

# If input field is empty, give error message and end script
if [ $# == 0 ]; then
    printf "$(basename $0): swaps between U's and T's in FastA file (DNA <--> RNA).\nVersion: ${script_version}\nContact Jackson M. Tsuji (jackson.tsuji@uwaterloo.ca) for bug reports or feature requests.\n\nUsage: $(basename $0) [U_to_T | T_to_U] input.fasta output.fasta\n\n*Note: all this script does is swap capital AND lowercase U's/T's in sequences (non-header) sections. Does not do anything to ambiguous bases.\n"
    exit 1
fi
# Using printf: http://stackoverflow.com/a/8467449 (accessed Feb 21, 2017)
# Test for empty variable: Bioinformatics Data Skills Ch. 12 pg 403-404, and http://www.tldp.org/LDP/Bash-Beginners-Guide/html/sect_09_07.html and http://stackoverflow.com/a/2428006 (both accessed Feb 21, 2017)

echo "Running $(basename $0), version $script_version."
echo ""

# Read in user input
direction=$1
input=$2
output=$3

# Check direction is valid
if [ $direction == "U_to_T" ]; then
    echo "Converting U's to T's (case insensitive)."
elif [ $direction == "T_to_U" ]; then
    echo "Converting T's to U's (case insensitive)."
else
    echo "ERROR: input conversion direction must match either 'U_to_T' or 'T_to_U'. Exiting... "
    exit 1
fi

# Run replacement
if [ $direction == "U_to_T" ]; then

    awk '{ if ($0 !~ /^>/) { \
    gsub("U", "T"); gsub("u", "t"); \
    } \
    print \
    } \
    ' \
    $input > $output

elif [ $direction == "T_to_U" ]; then

    awk '{ if ($0 !~ /^>/) { \
    gsub("T", "U"); gsub("t", "u"); \
    } \
    print \
    } \
    ' \
    $input > $output

fi

echo ""
echo "Replacing finished for input file $(basename ${input}). Output saved as $(basename ${output})."
echo ""

echo "$(basename $0): finished."
echo ""
