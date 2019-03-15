#!/usr/bin/env bash
set -euo pipefail

# run_whole_genome_phylogeny.sh
# Run a whole genome phylogeny for a set of prokaryotic genomes
# Copyright Jackson M. Tsuji, 2019

# Startup processes
VERSION=$(basic-sequence-analysis-version)
script_name=${0##*/}
script_name=${script_name%.*}

# If no input is provided, provide help and exit
if [ $# -lt 2 ]; then

	# Help statement
	printf "${script_name}: simple script to run whole genome phylogeny on a set of input FastA nuclteotide genome files.\n"
	printf "Copyright Jackson M. Tsuji, Neufeld Research Group, 2019\n"
	printf "Version: ${VERSION}\n"
	printf "Contact Jackson M. Tsuji (jackson.tsuji@uwaterloo.ca) for bug reports or feature requests.\n\n"
	printf "Installation: GToTree must be installed for this script to run. Designed for version 1.1.10. See the tutorial file for installation.\n\n"
	printf "Usage: ${0##*/} [OPTIONS] input_genome_directory output_directory 2>&1 | tee ${script_name}.log\n\n"
	printf "Positional arguments:\n"
	printf "   1. input_genome_directory: Path to the directory containing unzipped FastA nucleotide files for all genomes to be run. FastA files MUST have the extensions '*.fna' to be run!!\n"
	printf "   2. output_directory: Path to the directory where the genome phylogeny will be built. For safety, the script will not run if the directory already exists.\n\n"
	printf "Options (optional):\n"
	printf "   -@   threads: Number of parallel processors to use. (Default: 1)\n"
	printf "   -p   phylogenetic marker gene set: the exact name of any of the phylogenetic marker gene sets allowable in GToTree. Check the available sets by running the GToTree command 'gtt-hmms'. (Default: 'Universal_Hug_et_al.hmm')\n"
	printf "   -c   gtotree_outlier_length_threshold ('-c' setting in GToTree): Any amino acid sequences this much longer/shorter (proportionally) than the median length are exlcuded. (Default: 0.2)\n"
	printf "   -G   gtotree_minimum_hit_fraction ('-G' setting in GToTree): Genomes with fewer hits than this (proportionally) are exlcuded from the phylogeny. (Default: 0.5)\n"
	printf "   -b   iqtree_bootstraps: Number of bootstrap replicates. (Default: 1000).\n"
	printf "   -B   iqtree_boostrap_type: type of IQ-TREE bootstraps; either 'normal' ('-b' in IQ-TREE) or 'ultrafast' ('-bb' in IQ-TREE). (default: 'normal').\n"
	printf "   -m   iqtree_model: substitution model to use with IQ-TREE. Any model possible with IQ-TREE is acceptable. (Default: 'MFP' for automated best model selection)\n"
	printf "   -s   iqtree_phylogeny_seed: Seed for starting the phylogeny; any random number is okay. (Default: random)\n\n"
	# Exit
	exit 1
fi

# Set defaults for options
threads=1
gtotree_phylogenetic_marker_set="Universal_Hug_et_al.hmm"
gtotree_outlier_length_threshold=0.2 # -c setting; 0.2 is the default. Any amino acid sequences this much longer/shorter (proportionally) than the median length are exlcuded.
gtotree_minimum_hit_fraction=0.5 # -G setting; 0.5 is the default. Genomes with fewer hits than this are exlcuded from the phylogeny
iqtree_boostrap_type="normal" # Either 'normal' for standard bootstraps ('-b') or 'rapid' for rapid bootstraps ('-bb').
iqtree_bootstraps=1000
iqtree_phylogeny_seed=$((RANDOM%99+1)) # pseudo-random number between 1-100
iqtree_model="MFP"

# Set options (help from https://wiki.bash-hackers.org/howto/getopts_tutorial; accessed March 8th, 2019)
OPTIND=1 # reset the OPTIND counter just in case
while getopts ":@:p:c:G:s:b:B:m:" opt; do
	case ${opt} in
		\@)
			threads=${OPTARG}
			;;
		p)
			gtotree_phylogenetic_marker_set=${OPTARG}
			;;
		c)
			gtotree_outlier_length_threshold=${OPTARG}
			;;
		G)
			gtotree_minimum_hit_fraction=${OPTARG}
			;;
		s)
			iqtree_phylogeny_seed=${OPTARG}
			;;
		b)
			iqtree_bootstraps=${OPTARG}
			;;
		B)
			iqtree_boostrap_type=${OPTARG}
			;;
		m)
			iqtree_model=${OPTARG}
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
genome_dir=$1
output_dir=$2

# Check bootstrap type is valid and use to set bootstrap flag for later
if [ ${iqtree_boostrap_type} = "normal" ]; then
	iqtree_bootstrap_flag="b"
elif [ ${iqtree_boostrap_type} = "ultrafast" ]; then
	iqtree_bootstrap_flag="bb"
else
	(>&2 echo "[ $(date -u) ]: ERROR: iqtree_boostrap_type must be either 'normal' or 'ultrafast', but '${iqtree_boostrap_type}' was supplied. Exiting...")
	exit 1
fi

# Startup reporting
(>&2 echo "[ $(date -u) ]: Running ${script_name}")
(>&2 echo "[ $(date -u) ]: Version: ${VERSION}")
(>&2 echo "[ $(date -u) ]: Command: ${0##*/} ${original_arguments}")
(>&2 echo "[ $(date -u) ]: #### SETTINGS ####")
(>&2 echo "[ $(date -u) ]: input_genome_directory: ${genome_dir}")
(>&2 echo "[ $(date -u) ]: output_directory: ${output_dir}")
(>&2 echo "[ $(date -u) ]: threads: ${threads}")
(>&2 echo "[ $(date -u) ]: gtotree_phylogenetic_marker_set: ${gtotree_phylogenetic_marker_set}")
(>&2 echo "[ $(date -u) ]: gtotree_outlier_length_threshold: ${gtotree_outlier_length_threshold}")
(>&2 echo "[ $(date -u) ]: gtotree_minimum_hit_fraction: ${gtotree_minimum_hit_fraction}")
(>&2 echo "[ $(date -u) ]: iqtree_bootstraps: ${iqtree_bootstraps}")
(>&2 echo "[ $(date -u) ]: iqtree_boostrap_type: ${iqtree_boostrap_type}")
(>&2 echo "[ $(date -u) ]: iqtree_model: ${iqtree_model}")
(>&2 echo "[ $(date -u) ]: iqtree_phylogeny_seed: ${iqtree_phylogeny_seed}")
(>&2 echo "[ $(date -u) ]: ##################")

# Check if the output directory exists
if [ -d ${output_dir} ]; then
	(>&2 echo "[ $(date -u) ]: ERROR: output_directory '${output_dir}' already exists. Please delete it before running this script. Exiting...")
	exit 1
fi

# Make output subdirectories
mkdir -p ${output_dir}/phylogeny ${output_dir}/summary

# Get genome list
find ${genome_dir} -iname "*.fna" | sort -h > ${output_dir}/input_genomes.list # N.B., genomes must be unzipped fna files.

if [ $(find ${genome_dir} -iname "*.fna" | wc -l) = 0 ]; then
	(>&2 echo "[ $(date -u) ]: ERROR: found no files with extension '*.fna' in folder '${genome_dir}'. Exiting...")
	exit 1
fi

(>&2 echo "[ $(date -u) ]: detected $(find ${genome_dir} -iname "*.fna" | wc -l) genome files (extension '*fna') to run.")

# Run GToTree
(>&2 echo "[ $(date -u) ]: Running GToTree")
(>&2 echo "[ $(date -u) ]: Command: GToTree -f ${output_dir}/input_genomes.list -H ${gtotree_phylogenetic_marker_set} -o ${output_dir}/alignment -T IQ-TREE -c ${gtotree_outlier_length_threshold} -G ${gtotree_minimum_hit_fraction} -n ${threads} -j ${threads} > ${output_dir}/GToTree.log")
GToTree -f ${output_dir}/input_genomes.list -H ${gtotree_phylogenetic_marker_set} -o ${output_dir}/alignment -T IQ-TREE -c ${gtotree_outlier_length_threshold} -G ${gtotree_minimum_hit_fraction} -n ${threads} -j ${threads} > ${output_dir}/GToTree.log
(>&2 echo "[ $(date -u) ]: GToTree: finished. See log to confirm run details.")

# Move log and genome list to the GToTree folder
mv ${output_dir}/GToTree.log ${output_dir}/input_genomes.list ${output_dir}/alignment

# Re-make the phylogeny manually to use my preferred settings for IQ-TREE:
input_alignment_filepath="${output_dir}/alignment/Aligned_SCGs.faa"
name_base="${gtotree_phylogenetic_marker_set%.*}_phylogeny"

(>&2 echo "[ $(date -u) ]: Running IQ-TREE (could take time)")
(>&2 echo "[ $(date -u) ]: Command: iqtree -s ${input_alignment_filepath} -pre ${output_dir}/phylogeny/${name_base} -nt ${threads} -seed ${iqtree_phylogeny_seed} -${iqtree_bootstrap_flag} ${iqtree_bootstraps} -m ${iqtree_model} >/dev/null")
iqtree -s ${input_alignment_filepath} -pre ${output_dir}/phylogeny/${name_base} -nt ${threads} -seed ${iqtree_phylogeny_seed} -${iqtree_bootstrap_flag} ${iqtree_bootstraps} -m ${iqtree_model} >/dev/null
(>&2 echo "[ $(date -u) ]: IQ-TREE: finished. See log to confirm run details.")

# Make summary of key files
(>&2 echo "[ $(date -u) ]: Summarizing key output files")
cp ${output_dir}/alignment/GToTree.log ${output_dir}/alignment/Aligned_SCGs.faa ${output_dir}/phylogeny/${name_base}.treefile ${output_dir}/phylogeny/${name_base}.log ${output_dir}/summary

(>&2 echo "[ $(date -u) ]: Pipeline finished. See key output files in '${output_dir}/summary'.")

