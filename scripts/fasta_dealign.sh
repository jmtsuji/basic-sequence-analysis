#!/usr/bin/env bash
set -euo pipefail

# fasta_dealign.sh
# Copyright Jackson M. Tsuji, 2022
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
  printf "Copyright Jackson M. Tsuji, 2022\n"
  printf "Contact Jackson M. Tsuji (jackson.tsuji@lowtem.hokudai.ac.jp) for bug reports or feature requests.\n"
  printf "Dependencies: seqtk\n\n"
  printf "Usage: ${0##*/} input_aligned.fasta > output_dealigned.fasta\n\n"
  printf "Usage details:\n"
  printf "   - All this script does is remove dashes or dots in sequence (non-header) sections.\n"
  printf "   - To receive from STDIN, use '-' as the input_aligned.fasta entry\n\n"

  # Exit
  exit 1
fi

input=$1

seqtk seq -A "${input}" | \
awk '{ if ($0 !~ /^>/) { \
    gsub(/-|\./, ""); \
  } \
    print \
  }'
