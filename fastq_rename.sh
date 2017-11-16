#!/bin/bash
# Created April 7, 2016, by Jackson Tsuji
# Description: renames FastQ file sequence names to a sequential format following an identifier (currently built into the code, with the idea that it could one day be input by the user).
# Last updated: April 7, 2016

# Basic script stuff (from Buffalo's Bioinformatics Data Skills book):
set -e
set -u
set -o pipefail

script_version=0.0.1a

# Making simple output directory paths:
#seq_identifier=$1
input_file=$1
output_file=$2

echo "Running $0, version $script_version, on input FastQ file $input_file."
echo "**Will rename with a sequence identifier built into the awk code. Manually edit the script to change (just before ++i in the awk code)"

awk '{print (NR%4 == 1) ? "@1_" ++i : $0}' $input_file > $output_file
# awk code is using the "if, then, else" format: IF ? THEN : ELSE
# General idea: if row number is a multiple of four, then rename to the "id" variable appended by a numerical counter. Otherwise (i.e. row is not a multiple of four), print the entire original line

#seq_id_mod="@${seq_identifier}_"
#awk -v var="$seq_id_mod" '{print (NR%4 == 1) ? var ++i : $0}' $input_file > $output_file

# Some references:
##  Main awk code adapted from https://www.biostars.org/p/68477/ (accessed April 7, 2016), from Frederic Mahe
##  No longer used, but idea for awk -v option from http://stackoverflow.com/questions/19075671/how-to-use-shell-variables-in-awk-script (accessed April 7, 2016), from Chad

echo "Finished renaming FastQ file. Saved to $output_file"
