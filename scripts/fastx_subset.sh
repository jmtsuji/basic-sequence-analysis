#!/usr/bin/env bash
set -euo pipefail

# fasta_dealign.sh
# Copyright Jackson M. Tsuji, 2022
# Description: subsamples all FastX in specified folder to desired read number/fraction.

# Startup processes
VERSION=$(basic-sequence-analysis-version)
script_name=${0##*/}
script_name=${script_name%.*}

# If no input is provided, provide help and exit
if [ $# -lt 4 ]; then

  # Help statement
  printf "${script_name}: subsamples all FastX files in specified folder to desired read number/fraction. E.g., for titration in metagenomic assembly or rarefaction of FastA files.\n"
  printf "Version: ${VERSION}\n"
  printf "Copyright Jackson M. Tsuji, 2022\n"
  printf "Contact Jackson M. Tsuji (jackson.tsuji@lowtem.hokudai.ac.jp) for bug reports or feature requests.\n"
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

# Find FastX files
fastx_files=($(find ${input_dir} -maxdepth 1 -iname "*.fastq.gz" -o -iname "*.fastq" -o -iname "*.fasta.gz" -o -iname "*.fasta" -type f | sort -h))
(>&2 echo "[ $(date -u) ]: Identified ${#fastq_files[@]} FastX files")
(>&2 echo "[ $(date -u) ]: Subsetting files")

# Subsample
for fastq_file in ${fastq_files[@]}; do
	# Get simplified sequence name (for either gzipped or unzipped, FastA or FastX)
	# TODO - do this more elegantly. There is some risk with the current method if the user has odd names
	filename_base=${fastx_file%.fastq.gz}
	filename_base=${filename_base%.fastq}
	filename_base=${filename_base%.fasta.gz}
	filename_base=${filename_base%.fasta}
	filename_base=${filename_base##*/}

	(>&2 echo "[ $(date -u) ]: ${fastx_file##*/}")
	(>&2 echo "[ $(date -u) ]: Command: 'seqtk sample -s ${seed} ${fastx_file} ${subset_size} | gzip > ${output_dir}/${filename_base}.fastq.gz'")
	seqtk sample -s ${seed} ${fastx_file} ${subset_size} | gzip > ${output_dir}/${filename_base}.fastq.gz

done

(>&2 echo "[ $(date -u) ]: ${script_name}: finished.")

