#!/usr/bin/env bash
set -euo pipefail
# fastq_get_names.sh
# Prints names of sequences in a FastQ file
# Copyright Jackson M. Tsuji, 2022

# Startup processes
VERSION=$(basic-sequence-analysis-version)
script_name=${0##*/}
script_name=${script_name%.*}

if [ $# -lt 1 ]; then

  # Help statement
  printf "${script_name}: Prints names of sequences in a FastQ file.\n"
  printf "Version: ${VERSION}\n"
  printf "Copyright Jackson M. Tsuji, 2022\n"
  printf "Contact Jackson M. Tsuji (jackson.tsuji@lowtem.hokudai.ac.jp) for bug reports or feature requests.\n"
  printf "Dependencies: seqtk.\n\n"
  printf "Usage: ${0##*/} fastQ_file.fastq.gz > fastQ_names.list\n\n"
  printf "Details:\n"
  printf "    - **This is a 'quick and dirty' script and does not check the integrity of the input file\n"
  printf "    - Names are printed to STDOUT\n"
  printf "    - FastQ files can be gzipped or unzipped\n"
  printf "    - This script removes the leading '@' from the FastQ file name but preserves the end comment\n\n"

  # Exit
  exit 1
fi

# Processing user input variable
input_file=$1

# Awk code adapted from https://www.biostars.org/p/68477/ (accessed April 7, 2016), from Frederic Mahe
seqtk seq "${input_file}" | \
  awk '{ if (NR%4 == 1) { print $0 } }' | \
  cut -f 2- -d '@'
# General idea: if row number is a multiple of four, then rename to the "id" variable appended by a numerical counter. Otherwise (i.e. row is not a multiple of four), print the entire original line
