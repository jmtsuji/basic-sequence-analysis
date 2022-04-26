#!/usr/bin/env bash
set -euo pipefail

# seq_name_simplify.sh
# Copyright Jackson M. Tsuji, 2022
# Description: simplifies sequence names in FastA files to make them more suitable for bioinformatics analyses

# Startup processes
VERSION=$(basic-sequence-analysis-version)
script_name=${0##*/}
script_name=${script_name%.*}

# If no input is provided, provide help and exit
if [ $# -lt 1 ]; then

  # Help statement
  printf "${script_name}: simplifies sequence names in FastA files to make them more suitable for bioinformatics analyses.\n"
  printf "Version: ${VERSION}\n"
  printf "Copyright Jackson M. Tsuji, 2022\n"
  printf "Contact Jackson M. Tsuji (jackson.tsuji@lowtem.hokudai.ac.jp) for bug reports or feature requests.\n"
  printf "Dependencies: seqtk\n\n"
  printf "Usage: ${0##*/} input.fasta > output.fasta\n\n"
  printf "Usage details:\n"
  printf "   - All this script does is perform a gsub find/replace of special characters in FastA headers (and changes dots to dashed in sequence names).\n"
  printf "   - Input FastA files can be gzipped or unzipped. STDOUT output will be unzipped.\n"
  printf "   - To receive from STDIN use '-' as the input.fasta entry\n\n"

  # Exit
  exit 1
fi

input=$1

seqtk seq -A "${input}" | \
  awk '{ \
    if ($0 ~ /^>/) { \
        gsub("[^A-Za-z0-9>]", "_"); \
    } \
    else { \
        gsub(/\./, "-"); \
    } \
  print \
  } '

