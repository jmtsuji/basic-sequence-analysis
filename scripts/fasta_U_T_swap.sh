#!/usr/bin/env bash
set -euo pipefail

# fasta_dealign.sh
# Copyright Jackson M. Tsuji, 2022
# Description: Switches between DNA and RNA (U's and T's)

# Startup processes
VERSION=$(basic-sequence-analysis-version)
script_name=${0##*/}
script_name=${script_name%.*}

# If no input is provided, provide help and exit
if [ $# -lt 2 ]; then

  # Help statement
  printf "${script_name}: swaps between U's and T's in FastA file (DNA <--> RNA).\n"
  printf "Version: ${VERSION}\n"
  printf "Copyright Jackson M. Tsuji, 2022\n"
  printf "Contact Jackson M. Tsuji (jackson.tsuji@lowtem.hokudai.ac.jp) for bug reports or feature requests.\n"
  printf "Dependencies: basic bash/awk\n\n"
  printf "Usage: ${0##*/} [U_to_T | T_to_U] input.fasta > output.fasta\n\n"
  printf "Usage details:\n"
  printf "   - All this script does is swap capital AND lowercase U's/T's in sequences (non-header) sections. Does not do anything to ambiguous bases.\n"
  printf "   - To receive from STDIN use '-' as the input.fasta entry\n\n"

  # Exit
  exit 1
fi

direction=$1
input=$2

# Check direction is valid
if [ $direction == "U_to_T" ]; then
  (>&2 echo "Converting U's to T's (case insensitive)")
elif [ $direction == "T_to_U" ]; then
  (>&2 echo "Converting T's to U's (case insensitive)")
else
  echo "ERROR: input conversion direction must match either 'U_to_T' or 'T_to_U'. Exiting... "
  exit 1
fi

# Run replacement
if [ "${direction}" == "U_to_T" ]; then

  awk '{ if ($0 !~ /^>/) { \
      gsub("U", "T"); gsub("u", "t"); \
    } \
      print \
    }' \
    "${input}"

elif [ "${direction}" == "T_to_U" ]; then

  awk '{ if ($0 !~ /^>/) { \
      gsub("T", "U"); gsub("t", "u"); \
  } \
    print \
  }' \
  "${input}"

fi
