#!/bin/bash
#  seq_name_simplify_v3.sh
#  Created by Jackson Tsuji on June 1, 2015. Free to share without need for citation.
#  Last updated May 31, 2017
#
# Function: simplifies sequence names in FastA files to make them more suitable for bioinformatics analyses.
# Sources:
#   General awk help: http://www.grymoire.com/Unix/Awk.html#uh-0 (May 13, 2015, and June 1, 2015)
#   Read function: http://tldp.org/LDP/Bash-Beginners-Guide/html/sect_08_02.html (May 13, 2015)
#   Wildcard regex: http://www.panix.com/~elflord/unix/grep.html#wildcards (June 1, 2015)
#   Based off code sent to me by Michael Hall on June 17, 2013 via email.

# Basic script stuff (from Vince Buffalo's "Bioinformatics Data Skills" (1st Ed.) chapter 12, pg 397):
set -e
set -u
set -o pipefail

script_version=3.0.1

# If input field is empty, give error message and end script
if [ $# == 0 ]
then
printf "$(basename $0): simplifies FastA files to remove special characters.\n\nVersion:\t${script_version}\nUsage:\t\t$(basename $0) input.fasta > output.fasta \n\n"
exit 1
fi
# Using printf: http://stackoverflow.com/a/8467449 (accessed Feb 21, 2017)
# Test for empty variable: Bioinformatics Data Skills Ch. 12 pg 403-404, and http://www.tldp.org/LDP/Bash-Beginners-Guide/html/sect_09_07.html and http://stackoverflow.com/a/2428006 (both accessed Feb 21, 2017)

# Read input file name from user input into the script
input=$1
# will output to STDOUT

awk '{ \
    if ($0 ~ /^>/) { \
        gsub("[^A-Za-z0-9>]", "_"); \
    } \
    else { \
        gsub(/\./, "-"); \
    } \
print \
} \
' \
$input
