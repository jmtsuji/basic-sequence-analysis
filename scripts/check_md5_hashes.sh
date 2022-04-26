#!/usr/bin/env bash
set -euo pipefail

# seq_name_simplify.sh
# Copyright Jackson M. Tsuji, 2022
# Description: MD5 hash checker for all fastq.gz files in a folder (must have a corresponding MD5 hash with same name but .md5 appended)

# Startup processes
VERSION=$(basic-sequence-analysis-version)
script_name=${0##*/}
script_name=${script_name%.*}

# If no input is provided, provide help and exit
if [ $# -lt 1 ]; then

  # Help statement
  printf "${script_name}: MD5 hash checker for all fastq.gz files in a folder.\n"
  printf "Version: ${VERSION}\n"
  printf "Copyright Jackson M. Tsuji, 2022\n"
  printf "Contact Jackson M. Tsuji (jackson.tsuji@lowtem.hokudai.ac.jp) for bug reports or feature requests.\n"
  printf "Dependencies: seqtk\n\n"
  printf "Usage: ${0##*/} input_directory | tee hash_check.tsv\n\n"
  printf "Usage details:\n"
  printf "   - Searches for all files with extension .fastq.gz and then performs an MD5 hash. Tests against .fastq.gz.md5 files that must already be in the same folder.\n"
  printf "   - Will look in all subdirectories of the input folder for FastQ files\n\n"

  # Exit
  exit 1
fi

# Get user input
work_directory=$1

# Find the FastQ files
fastq_files=($(find "${work_directory}" -iname "*.fastq.gz" | sort -h))
cd "${work_directory}"

# Make the header for the tab-separated file.
printf "Filename\tMD5_match_status\n"

# Check MD5 hashes
for file in "${fastq_files[@]}"; do
	# Get the base name of the file
	file_base="${file##*/}"

	# TODO - check if the required existing MD5 hash is present!!

	# Calculate the MD5 hash
	md5_hash_new=$(cat "${file}" | md5sum)

	# Get the existing MD5 hash
	md5_hash_old=$(cut -d ' ' -f 1 "${file.md5}")

	# Compare the hashes
	if [ "${md5_hash_new}" = "${md5_hash_old}" ]; then
	   printf "${file_base}\tpassed\n"
	else
	   printf "${file_base}\tFAILED\n"
	fi
done

# TODO - give an overall report of number passed/failed.

