#!/usr/bin/env bash
set -euo pipefail

# MD5 hash checker for all fastq.gz files in a folder
# Works for metagenomes from TCAG.
# Jackson M. Tsuji (Neufeld Research Group), 2018

work_directory=$1
# E.g., /Winnebago/Data/sthijs/HiSeq_data/ENG6210/180514_D00124_0548_AHGN3CBCX2

# Find the FastQ files
fastq_files=($(find ${work_directory} -name "*.fastq.gz"))
cd ${work_directory}

# Make the header for the tab-separated file.
printf "Filename\tMD5_match_status\n"

for file in ${fastq_files[@]}; do
	# Get the name of the file without the directory in front, to be compatible with TCAG naming
	file_base=${file##*/}

	# Calculate the MD5 hash
	md5sum ${file_base} > ${file_base}_neufeldserver.md5

	# Compare to the existing MD5 hash from TCAG in the folder. Print tab-separated for nice output for the user.
	if [ $(cmp ${file_base}_neufeldserver.md5 ${file_base}.md5 >/dev/null; echo $?) = 0 ]; then
	   printf "${file_base}\tOkay\n"
	else
	   printf "${file_base}\tNot_okay\n"
	fi
done
