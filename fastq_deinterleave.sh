#!/usr/bin/env bash
set -euo pipefail

# fastq_deinterleave.sh
# Copyright Jackson M. Tsuji, Neufeld Research Group, 2019

# If no input is provided, provide help and exit
if [ $# -lt 2 ]; then
	# Assign script name
	script_name=${0##*/}
	script_name=${0%.*}

	# Help statement
	printf "${0##*/}: simple script to iteratively deinterleave gzipped FastQ files.\n"
	printf "Copyright Jackson M. Tsuji, Neufeld Research Group, 2019\n"
	printf "Contact Jackson M. Tsuji (jackson.tsuji@uwaterloo.ca) for bug reports or feature requests.\n\n"
	printf "Installation: the bbmap suite's 'reformat.sh' is a dependency. You can install in a conda environment, e.g.,\n"
	printf "              conda create -n bbmap -c bioconda bbmap\n"
	printf "              conda activate bbmap\n\n"
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

# Make output dir
mkdir -p ${output_dir}

(>&2 echo "[ $(date -u) ]: Deinterleaving the FastQ files...")
for fastq_file in ${interleaved_fastq_files[@]}; do

	# Get truncated version of file name without folder paths
	fastq_file_base=${fastq_file%.fastq.gz}
	fastq_file_base=${fastq_file_base##*/}

	echo "[ $(date -u) ]: ${fastq_file_base}"

        # Run the deinterleaver and print log if something goes wrong
        reformat.sh in="${fastq_file}" out="${output_dir}/${fastq_file_base}_R1.fastq.gz" \
                out2="${output_dir}/${fastq_file_base}_R2.fastq.gz" verifyinterleaved=t ow=t 2>/dev/null || \
                ( rm "${output_dir}/${fastq_file_base}_R1.fastq.gz" "${output_dir}/${fastq_file_base}_R2.fastq.gz" && \
                reformat.sh in="${fastq_file}" out="${output_dir}/${fastq_file_base}_R1.fastq.gz" \
                        out2="${output_dir}/${fastq_file_base}_R2.fastq.gz" verifyinterleaved=t ow=t || \
                rm "${output_dir}/${fastq_file_base}_R1.fastq.gz" "${output_dir}/${fastq_file_base}_R2.fastq.gz" && \
                echo "[ $(date -u) ]: ERROR: failed at '${fastq_file_base}' -- see info above. Exiting..." && \
                exit 1 )

done

(>&2 echo "[ $(date -u) ]: ${0##*/}: Finished.")

