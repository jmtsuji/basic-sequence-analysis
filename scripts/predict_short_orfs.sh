#!/usr/bin/env bash
set -euo pipefail
# predict_short_orfs.sh
# Jackson M. Tsuji, ILTS, 2021

VERSION=$(basic-sequence-analysis-version)
script_name=${0##*/}
script_name=${script_name%.*}

# If no input is provided, provide help and exit
if [ $# -lt 1 ]; then

	# Help statement
	printf "${script_name}: predicts short ORFs from short read metagenome data.\n"
	printf "Version: ${VERSION}\n"
	printf "Copyright Jackson M. Tsuji, ILTS Microbial Ecology Group, Hokkaido University, 2021\n"
	printf "Contact Jackson M. Tsuji (jackson.tsuji@lowtem.hokudai.ac.jp) for bug reports or feature requests.\n"
	printf "Dependencies: bbmap>38, FGS++\n\n"
	printf "Usage: ${0##*/} [OPTIONS] input.fastq.gz > output.faa\n\n"

	printf "Positional arguments:\n"
	printf "   1. input.fastq.gz: Path to the input short reads. In theory any FastX format, gzipped or not, is okay, but typical use is gzipped FastQ.\n\n"

	printf "Options (optional):\n"
   	printf "   -p   threads: number of parallel threads to use. [Default: 1]\n"
    printf "   -t   fgs_model: Model file for FGS, located in the training file directory [Default: illumina_10].'\n"
   	printf "   -r   fgs_train_dir: Path to the FragGeneScan training file directory [Default: ${CONDA_PREFIX}/bin/train]\n"
   	printf "   -l   logfile: Optionally write a logfile to the filepath specified here [Default: /dev/stderr]\n\n"

	printf "Usage details:\n"
	printf "   - To receive from STDIN, use 'stdin' as the input.fastq.gz entry (using bbmap standards)\n\n"

	# Exit
	exit 1
fi

# Set defaults for options
threads=1
fgs_model="illumina_10"
fgs_train_dir="${CONDA_PREFIX}/bin/train"
# TODO - if CONDA_PREFIX is not set, then default should just be the current directory.
logfile="/dev/stderr"

# Set options (help from https://wiki.bash-hackers.org/howto/getopts_tutorial; accessed March 8th, 2019)
OPTIND=1 # reset the OPTIND counter just in case
while getopts ":t:r:p:l:" opt; do
	case ${opt} in
		t)
			fgs_model=${OPTARG}
			;;
		r)
			fgs_train_dir=${OPTARG}
			;;
		p)
			threads=${OPTARG}
			;;
		l)
			logfile=${OPTARG}
			;;
		\?)
			(>&2 echo "[ $(date -u) ]: ERROR: Invalid option: '-${OPTARG}'. Exiting...")
			exit 1
			;;
		:)
			(>&2 echo "[ $(date -u) ]: ERROR: argument needed following '-${OPTARG}'. Exiting...")
			exit 1
			;;
    esac
done

# Set positional arguments
original_arguments=${@} # save for reporting later
shift $((OPTIND - 1)) # shift to avoid flags when assigning positional arguments
input_filepath=$1

# Initialize logfile
printf "" > "${logfile}"

# Startup info
echo "[ $(date -u) ]: Running ${0##*/}" >> "${logfile}"
echo "[ $(date -u) ]: Version: ${VERSION}" >> "${logfile}"
echo "[ $(date -u) ]: Command: ${0##*/} ${original_arguments}" >> "${logfile}"
echo "[ $(date -u) ]: #### SETTINGS ####" >> "${logfile}"
echo "[ $(date -u) ]: input_filepath: ${input_filepath}" >> "${logfile}"
echo "[ $(date -u) ]: fgs_model: ${fgs_model}" >> "${logfile}"
echo "[ $(date -u) ]: fgs_train_dir: ${fgs_train_dir}" >> "${logfile}"
echo "[ $(date -u) ]: threads: ${threads}" >> "${logfile}"
echo "[ $(date -u) ]: logfile: ${logfile}" >> "${logfile}"
echo "[ $(date -u) ]: ##################" >> "${logfile}"

echo "[ $(date -u) ]: Running ORF prediction (log contents below)" >> ${logfile}

reformat.sh in="${input_filepath}" out=stdout.fa threads="${threads}" fastawrap=0 \
    trimreaddescription=t fixheaders=t 2>>"${logfile}" | \
  FGS++ -s stdin -o stdout -w 0 -r "${fgs_train_dir}" \
    -t "${fgs_model}" -p "${threads}" -m 50000 2>>"${logfile}"
# TODO - this is a little odd because the FGS++ log will be printed concurrently into the same file
#        as the reformat log. In practice, it works because FGSpp will just print a "Run finished with xx threads"
#        message after finishing, i.e., at the very bottom of the log.
# TODO - FGS++ logfile does not seem to print...

echo "[ $(date -u) ]: ORF prediction finished. Script finished." >> ${logfile}
