#!/usr/bin/env bash
set -euo pipefail

# run_whole_genome_phylogeny.sh
# Description: Given unaligned input sequences, creates a 16S rRNA gene phylogeny truncated to the region of interest.
# Copyright Jackson M. Tsuji, 2022

script_version=$(basic-sequence-analysis-version)
date_code=$(date '+%y%m%d')

# If input field is empty, print help and end script
if [ $# == 0 ]; then
  printf "\n$(basename $0): automated 16S/18S rRNA gene alignment and phylogeny building\n"
  printf "Version: ${script_version}\n"
  printf "Contact Jackson M. Tsuji (jackson.tsuji@lowtem.hokudai.ac.jp) for error reports or feature requests.\n\n"
  printf "Usage: $(basename $0) input_16S.fasta 16S_start 16S_end 16S_model RAxML_iterations seq_evol_model threads 2>&1 | tee $(basename $0 .sh).log \n\n"
  printf "Positional arguments:\n"
  printf "1. input_16S.fasta: should be an unaligned FastA file containing 16S/18S rRNA gene sequences. Avoid very long sequence names or special characters in sequence names (can cause problems with RAxML).\n"
  printf "2-3. 16S_start/end: start and end positions to truncate the 16S alignment to, compared to a standard reference alignment (like the position #s on 16S PCR primers, like 341f-806r).\n"
  printf "4. 16S_model: either bacteria, archaea, or eukarya (lowercase), to guide model usage for ssu-align\n"
  printf "5. RAxML iterations: number of maximum likelihood iterations when making the tree (e.g., 100).\n"
  printf "6. seq_evol_model (sequence evolution model): See RAxML manual for possible sequence evolution models, e.g., GTRCAT.\n"
  printf "7. threads: Number of threads for making phylogenetic tree.\n\n"
  printf "Notes:\n"
  printf "  - Output: note that your output will be saved to the folder where you run this script and will have output names based on the input file name.\n\n"
  printf "Dependencies: ssu-align and RAxML (raxmlHPC-PTHREADS-SSE3).\n\n"
  exit 1
fi

#################################################################
##### Settings: #################################################
out_dir=$(pwd) # means you have to run the script in this folder.

input=$(realpath $1) # unaligned FastA file
start=$2
end=$3
model=$4
iterations=$5
seq_evol_model=$6
threads=$7
#################################################################

echo "Running $(basename $0) version $script_version on ${date_code} (yymmdd). Will use ${threads} threads for RAxML."
echo ""

# Test that the input file exists
if [ ! -f ${input} ]; then
  print "Did not find 16S sequence file at ${metagenome_file_pairs_info}. Job terminating."
  exit 1
fi

# Test that the provided 16S model is correct
if [ $model != "bacteria" -a $model != "archaea" -a $model != "eukarya" ]; then
  print "ERROR: 16S_model must be either bacteria, archaea, or eukarya. You provided ${model}. Exiting..."
  exit 1
fi

start_time=$(date)

# Make output directory and go there (should be a redundant step)
mkdir -p $out_dir
cd $out_dir

# Get simplified input name to use to make output file names via two parameter substitutions (remove directories, then remove final extension). Also save extension.
base=${input##*/}
ext=${base##*.}
base=${base%.*}

####################################
####### Processing strategy ########
####################################
# 1a. Build custom covariance model for 16S region of interest using ssu-build
# 1b. Align to the covariance model using ssu-align
# 2a. Create maximum likelihood tree using RAxML
# 2b. Provide node support using the SH test built into RAxML
####################################

mkdir -p ${out_dir}/01_alignment/model
mkdir -p ${out_dir}/02_phylogeny
mkdir -p ${out_dir}/03_summary/logs

##############################
##### 1. Build custom CM and align using the CM ############
##############################
cd ${out_dir}/01_alignment/model

# Get version and protect from exiting out
set +e
ssu_build_version=$(ssu-build -h 2>&1 | head -n 2 | tail -n 1 | cut -d ' ' -f 3)
set -e
echo "Building custom CM truncated to ${start}-${end} (${model}) using ssu-build version ${ssu_build_version}..."

# Specify new names and paths of files to be created (to make subsequent steps easier)
cm_name=${model:0:3}-${start}-${end}
ssu-build -d --trunc ${start}-${end} -n ${cm_name} -o ${cm_name}.cm ${model} 2>&1 > /dev/null

# Make alignment using the CM
cd ..
# Get version and protect from exiting out
set +e
ssu_align_version=$(ssu-align -h 2>&1 | head -n 2 | tail -n 1 | cut -d ' ' -f 3)
set -e
echo "Aligning ${base}.${ext} using ssu-align version ${ssu_align_version}..."

aln_name="${base}_aln"
ssu-align -m model/${cm_name}.cm ${input} ${aln_name} 2>&1 > /dev/null

# Mask uninformative regions
ssu-mask -m model/${cm_name}.cm ${aln_name} 2>&1 > /dev/null

# Convert to FastA (masked and unmasked, for reference)
ssu-mask --stk2afa -a ${aln_name}/${aln_name}.${cm_name}.stk 2>&1 > /dev/null
ssu-mask --stk2afa -a ${aln_name}/${aln_name}.${cm_name}.mask.stk 2>&1 > /dev/null
mv *.log *.sum ${aln_name}

# Output file names that should have been produced:
unmaked_aln="${aln_name}.${cm_name}.afa"
masked_aln="${aln_name}.${cm_name}.mask.afa"

# For now, will used the MASKED one for the next step.


##############################
##### 2. RAxML tree ##############
##############################
cd ${out_dir}/02_phylogeny

# Get RAxML version
set +e # Have to temporarily allow for an exit status 1 from pear
raxml_version=$(raxmlHPC-PTHREADS-SSE3 -v 2>&1 | head -n 3 | tail -n 1 | cut -d ' ' -f 5)
set -e
echo "Building phylogeny with ${iterations} iterations and ${seq_evol_model} sequence evolution model..."

# Get random SEED
seed=$RANDOM # Ranges from 0 to 32767 according to http://tldp.org/LDP/abs/html/randomvar.html (accessed 171119)

echo "SEED: ${seed}"

# Build the phylogenetic tree
raxmlHPC-PTHREADS-SSE3 -T ${threads} -m ${seq_evol_model} -p ${seed} -s "../01_alignment/${masked_aln}" -# ${iterations} -n "${base}.1" 2>&1 > /dev/null

# Add branch support
raxmlHPC-PTHREADS-SSE3 -T ${threads} -m ${seq_evol_model} -n "${base}.2" -s "../01_alignment/${masked_aln}" -p ${seed} -f J -t "RAxML_bestTree.${base}.1" 2>&1 > /dev/null


#### Summarizing output for user
echo "Summarizing output..."
cd ${out_dir}/03_summary
cp ../01_alignment/model/*.pdf . # Visualization of the truncation region
cp ../01_alignment/${masked_aln} . # FastA used for tree-building
cp ../02_phylogeny/RAxML_fastTreeSH_Support.${base}.2 . # Tree with SH support

# Copy key logs, then tar-gzip folder
cp ../01_alignment/model/*.sum logs
cp ../01_alignment/${aln_name}/${aln_name}.ssu-align.sum logs
cp ../01_alignment/${aln_name}/${aln_name}.ssu-mask.sum logs
cp ../02_phylogeny/RAxML_info* logs

tar -czf logs.tar.gz logs 2>&1 > /dev/null
if [ -f logs.tar.gz ]; then
  rm -r logs
else
  echo "Problem summarizing log files."
fi

# Gzip phylogeny folder
cd ..

tar -czf 02_phylogeny.tar.gz 02_phylogeny 2>&1 > /dev/null
if [ -f 02_phylogeny.tar.gz ]; then
  rm -r 02_phylogeny
else
  echo "Problem compressing phylogeny information."
fi


end_time=$(date)

echo ""
echo ""

echo "$(basename $0): finished. Output can be found in ${out_dir}."
echo "Started at ${start_time} and finished at ${end_time}."
echo ""
