#!/usr/bin/env bash
set -euo pipefail

# run_whole_genome_phylogeny.sh
# Run a whole genome phylogeny for a set of prokaryotic genomes
# Copyright Jackson M. Tsuji, 2019

# If no input is provided, provide help and exit
if [ $# -lt 3 ]; then
	# Assign script name
	script_name=${0##*/}
	script_name=${0%.*}

	# Help statement
	printf "${script_name}: simple script to run whole genome phylogeny on a set of input FastA nuclteotide genome files.\n"
	printf "Copyright Jackson M. Tsuji, Neufeld Research Group, 2019\n"
	printf "Contact Jackson M. Tsuji (jackson.tsuji@uwaterloo.ca) for bug reports or feature requests.\n\n"
	printf "Installation: GToTree must be installed for this script to run. Designed for version 1.1.5.\n\n"
	printf "Usage: ${script_name} input_genome_directory output_directory threads 2>&1 | tee ${script_name}.log\n\n"
	printf "Usage details:\n"
	printf "   1. input_genome_directory: Path to the directory containing unzipped FastA nucleotide files for all genomes to be run. FastA files MUST have the extensions '*.fna' to be run!!\n"
	printf "   2. output_directory: Path to the directory where the genome phylogeny will be built.\n"
	printf "   3. threads: Number of parallel threads to use in the analysis.\n"
	printf "   4. phylogenetic marker gene set (OPTIONAL): the exact name of any of the phylogenetic marker gene sets allowable in GToTree (default: 'Universal_Hug_et_al.hmm'). Check the available sets by running the GToTree command 'gtt-hmms'.\n\n"
	# Exit
	exit 1
fi

# Set user variables
genome_dir=$1
output_dir=$2
threads=$3

# Optionally set the phylogenetic marker gene set
if [ $# -eq 4 ]; then
	gtotree_phylogenetic_marker_set=$4
elif if [ $# -eq 3 ]; then
	gtotree_phylogenetic_marker_set="Universal_Hug_et_al.hmm" # You can change this to any option allowable by GToTree.
fi

# HARD-CODED variables
gtotree_outlier_length_threshold=0.2 # -c setting; 0.2 is the default. Any amino acid sequences this much longer/shorter (proportionally) than the median length are exlcuded.
gtotree_minimum_hit_fraction=0.5 # -G setting; 0.5 is the default. Genomes with fewer hits than this are exlcuded from the phylogeny
iqtree_boostrap_type="normal" # Either 'normal' for standard bootstraps ('-b') or 'rapid' for rapid bootstraps ('-bb').
iqtree_bootstraps=1000
iqtree_phylogeny_seed=53 # random number; can change as you like

# Startup reporting
(>&2 echo "[ $(date -u) ]: Running ${0##*/}")
(>&2 echo "[ $(date -u) ]: Command: ${0##*/} ${@}")
(>&2 echo "[ $(date -u) ]: input_genome_directory: ${genome_dir}")
(>&2 echo "[ $(date -u) ]: output_directory: ${output_dir}")
(>&2 echo "[ $(date -u) ]: threads: ${threads}")
(>&2 echo "[ $(date -u) ]: gtotree_phylogenetic_marker_set: ${gtotree_phylogenetic_marker_set}")

# Make output directories
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

if [ ${iqtree_boostrap_type} = "normal" ]; then
	iqtree_bootstrap_flag="b"
elif [ ${iqtree_boostrap_type} = "rapid" ]; then
	iqtree_bootstrap_flag="bb"
else
	(>&2 echo "[ $(date -u) ]: ERROR: iqtree_boostrap_type must be either 'normal' or 'rapid', but ${iqtree_boostrap_type} was supplied. Exiting...")
	exit 1
fi

(>&2 echo "[ $(date -u) ]: Running IQ-TREE with ${threads} threads and ${iqtree_bootstraps} '${iqtree_boostrap_type}' bootstrap replicates (could take time)")
(>&2 echo "[ $(date -u) ]: Command: iqtree -s ${input_alignment_filepath} -pre ${output_dir}/phylogeny/${name_base} -nt ${threads} -seed ${iqtree_phylogeny_seed} -${iqtree_bootstrap_flag} ${iqtree_bootstraps} -m MFP >/dev/null")
iqtree -s ${input_alignment_filepath} -pre ${output_dir}/phylogeny/${name_base} -nt ${threads} -seed ${iqtree_phylogeny_seed} -${iqtree_bootstrap_flag} ${iqtree_bootstraps} -m MFP >/dev/null
(>&2 echo "[ $(date -u) ]: IQ-TREE: finished. See log to confirm run details.")

# Make summary of key files
(>&2 echo "[ $(date -u) ]: Summarizing key output files")
cp ${output_dir}/alignment/GToTree.log ${output_dir}/alignment/Aligned_SCGs.faa ${output_dir}/phylogeny/${name_base}.treefile ${output_dir}/phylogeny/${name_base}.log ${output_dir}/summary

(>&2 echo "[ $(date -u) ]: Pipeline finished. See key output files in '${output_dir}/summary'.")

