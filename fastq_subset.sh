#!/usr/bin/env bash
set -euo pipefail

# fasta_dealign.sh
# Copyright Jackson M. Tsuji, Neufeld Research Group, 2019
# Description: subsamples all samples in specified folder to desired read number/fraction.

VERSION=$(basic-sequence-analysis-version)

# If no input is provided, provide help and exit
if [ $# -lt 2 ]; then
	# Assign script name
	script_name=${0##*/}
	script_name=${script_name%.*}

	# Help statement
	printf "${script_name}: subsamples all samples in specified folder to desired read number/fraction.\n"
	printf "Version: ${VERSION}\n"
	printf "Copyright Jackson M. Tsuji, Neufeld Research Group, 2019\n"
	printf "Contact Jackson M. Tsuji (jackson.tsuji@uwaterloo.ca) for bug reports or feature requests.\n"
	printf "Dependencies: seqtk\n\n"
	printf "Usage: ${0##*/} input_directory output_directory subset_size seed 2>&1 | tee $(basename $0 .sh).log\n\n"
	printf "Usage details:\n"
	printf "   - Input FastQ files can be gzipped or unzipped. Will be saved as gzipped.\n"
	printf "   - input_directory: Files in subfolders will not be subsetted.\n"
	printf "   - output_directory: Will be created if it does not already exist. If it does exist, any files with same names will be OVERWRITTEN!\n"
	printf "   - subset_size: Number of sequences of proportion of sequences to keep.\n"
	printf "   - seed: Random seed for the subset algorithm.\n\n"

	# Exit
	exit 1
fi

# Receive user input
input_dir=$1
output_dir=$2
subset_size=$3
seed=$3
#################################################################

(>&2 echo "[ $(date -u) ]: Running ${0##*/}")
(>&2 echo "[ $(date -u) ]: Command: ${0##*/} ${@}")
(>&2 echo "[ $(date -u) ]: input_dir: ${input_dir}")
(>&2 echo "[ $(date -u) ]: output_dir: ${output_dir}")
(>&2 echo "[ $(date -u) ]: subset_size: ${output_dir}")
(>&2 echo "[ $(date -u) ]: seed: ${output_dir}")

mkdir -p ${output_dir}

# Find FastQ files
fastq_files=($(find ${input_dir} -maxdepth 1 -iname "*.fastq.gz" -o -iname "*.fastq" -type f | sort -h))
(>&2 echo "[ $(date -u) ]: Identified ${#fastq_files[@]} FastQ files")
(>&2 echo "[ $(date -u) ]: Subsetting files")

# Subsample
for fastq_file in ${fastq_files[@]}; do
	# Get simplified sequence name (for either gzipped or unzipped)
	filename_base=${fastq_file%.fastq.gz}
	filename_base=${filename_base%.fastq}
	filename_base=${filename_base##*/}

	(>&2 echo "[ $(date -u) ]: ${filename_base##*/}")
	seqtk sample -s ${seed} ${fastq_file} ${subset_size} | gzip > ${output_dir}/${filename_base}.fastq.gz

done

(>&2 echo "[ $(date -u) ]: ${script_name}: finished.")

