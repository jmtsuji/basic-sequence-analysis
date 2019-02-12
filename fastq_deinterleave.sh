#!/usr/bin/env bash
set -euo pipefail

# fastq_deinterleave.sh
# Copyright Jackson M. Tsuji, Neufeld Research Group, 2019

# If no input is provided, provide help and exit
if [ $# == 0 ]; then
	# Assign script name
	script_name=${0##*/}
	script_name=${0%.*}

	# Help statement
	printf "${0##*/}: simple script to iteratively deinterleave gzipped FastQ files.\n"
	printf "Copyright Jackson M. Tsuji, Neufeld Research Group, 2019\n"
	printf "Contact Jackson M. Tsuji (jackson.tsuji@uwaterloo.ca) for bug reports or feature requests.\n\n"
	printf "Usage: ${0##*/} input_dir output_dir 2>&1 | tee ${script_name}.log\n\n"
	printf "Usage details:\n"
	printf "   1. input_dir: Path to the directory containing gzipped interleaved FastQ files. Interleaved FastQ files MUST have the extension .fastq.gz!!\n"
	printf "   2. output_dir: Path to the directory where you want the deinterleaved files to be output. Anything already there might be overwritten -- be careful. Output files will have _R1 and _R2 appended to the end of the filenames.\n\n"
	# Exit
	exit 1
fi

# Set user variables
input_dir=$1
output_dir=$2

# Startup reporting
(>&2 echo "[ $(date -u) ]: Running ${0##*/}")
(>&2 echo "[ $(date -u) ]: Command: ${0##*/} ${@}")
(>&2 echo "[ $(date -u) ]: input_dir: ${input_dir}")
(>&2 echo "[ $(date -u) ]: output_dir: ${output_dir}")

# Find input files
interleaved_fastq_files=($(find ${input_dir} -iname "*.fastq.gz"))
(>&2 echo "[ $(date -u) ]: Found ${#interleaved_fastq_files[@]} gzipped FastQ files.")

(>&2 echo "[ $(date -u) ]: Deinterleaving the FastQ files...")
for fastq_file in ${interleaved_fastq_files[@]}; do

	# Get truncated version of file name without folder paths
	fastq_file_base=${fastq_file%.fastq.gz}
	fastq_file_base=${fastq_file_base##*/}

	echo "[ $(date -u) ]: ${fastq_file_base}"

	# Warn user if it looks like it might not need deinterleaving
	file_ending=$(echo ${fastq_file_base} | tr "_" " " | awk '{ print $NF }')
	if [ ${file_ending} == "R1" ]; then
		echo "[ $(date -u) ]: WARNING: '${fastq_file_base}' ends with 'R1' -- is it already deinterleaved?? Check this file..."
	elif [ ${file_ending} == "R2" ]; then
		echo "[ $(date -u) ]: WARNING: '${fastq_file_base}' ends with 'R2' -- is it already deinterleaved?? Check this file..."
	fi

	# De-interleave based on to https://www.biostars.org/p/141256/#142018 (accessed 171115)
	gunzip -c ${fastq_file} | paste - - - - - - - - \
	| tee >(cut -f 1-4 | tr "\t" "\n" | gzip > ${output_dir}/${fastq_file_base}_R1.fastq.gz) \
	| cut -f 5-8 | tr "\t" "\n" | gzip > ${output_dir}/${fastq_file_base}_R2.fastq.gz

done

(>&2 echo "[ $(date -u) ]: ${0##*/}: Finished.")

