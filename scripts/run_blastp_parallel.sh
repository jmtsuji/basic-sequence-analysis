#!/usr/bin/env bash
set -euo pipefail
# run_blastp_parallel.sh
# Copyright Jackson M. Tsuji, Neufeld lab, 2019
# Runs BLASTP in parallel to find closest hits for given queries. Also outputs taxonomy.
# NOTE: script is still in development.

# GLOBAL VARIABLES
VERSION=$(basic-sequence-analysis-version)
SCRIPT_NAME=${0##*/}

# PRESETS - set these up for your server!
DB_NAME="refseq_protein"
BLASTDB="/Data/reference_databases/blast/refseq_protein_191010"
TAXDUMP_LOCATION="${BLASTDB}/taxdump"
LINEAGE_REPO_LOCATION="/Data/reference_databases/blast/2018-ncbi-lineages"
# Get this github repo via 'git clone https://github.com/dib-lab/2018-ncbi-lineages.git' and note the last commit ID for your records

# If incorrect input is provided, provide help and exit
if [ $# -ne 1 -a $# -ne 5 ]; then
  printf "Error: missing or extra arguments supplied. To see help statement, run '${SCRIPT_NAME} -h'\n" >&2
  exit 1
elif [ $1 = "-h" -o $1 = "--help" ]; then
  # Help statement
  printf "${SCRIPT_NAME}: Runs BLASTP in parallel to find closest hits for given queries. Also outputs taxonomy.\n"
  printf "Version: ${VERSION}\n"
  printf "Copyright Jackson M. Tsuji, Neufeld Research Group, 2019\n"
  printf "Dependencies: BLAST+\n\n"
  printf "Usage: ${SCRIPT_NAME} query_faa output_tsv evalue max_targets threads\n\n"
  printf "Notes:\n"
  printf "  - some settings are preset inside the code for this script for running blast. Modify the PRESETS section of the code to change these.\n"

  # Exit
  exit 1
fi

# Receive user input
# TODO - change some of these to flags for clarity
query_filepath=$(realpath $1)
output_filepath=$(realpath $2)
evalue=$3
max_target_seqs=$4 # max number of results to display per gene
threads=$5

# Set up tmp outputs
output_tmpdir="${output_filepath%/*}/blastp_tmp"
output_basepath="${output_tmpdir}/blastp_tmp"

# Check inputs
if [[ ! -f "${query_filepath}" ]]; then
  echo "[ $(date -u) ]: ERROR: input file not found at '${query_filepath}'. Exiting..." >&2
  exit 1
elif [[ "${query_filepath##*.}" != "faa" ]]; then
  echo "[ $(date -u) ]: WARNING: extension of input file is '${query_filepath##*.}' (expecteding 'faa')" >&2
fi

# Check outputs
if [[ -f "${output_filepath}" ]]; then
  echo "[ $(date -u) ]: ERROR: another file is already present at desired output filepath '${output_filepath}'. Refusing to continue..." >&2
  exit 1
elif [[ ! -d "${output_filepath%/*}" ]]; then
  echo "[ $(date -u) ]: ERROR: desired directory for output file '${output_filepath}' does not exist. Please make this folder. Exiting..." >&2
  exit 1
elif [[ -d "${output_tmpdir}" ]]; then
  echo "[ $(date -u) ]: ERROR: tmp output directory '${output_tmpdir}' already exists. Refusing to continue..." >&2
  exit 1
fi

# Startup messages
echo "[ $(date -u) ]: Running ${SCRIPT_NAME}" >&2
echo "[ $(date -u) ]: Version: ${VERSION}" >&2
echo "[ $(date -u) ]: Command run: ${SCRIPT_NAME} ${@}" >&2
echo "[ $(date -u) ]: ######## PRESETS ########" >&2
echo "[ $(date -u) ]: DB_NAME: '${DB_NAME}'" >&2
echo "[ $(date -u) ]: BLASTDB: '${BLASTDB}'" >&2
echo "[ $(date -u) ]: TAXDUMP_LOCATION: '${TAXDUMP_LOCATION}'" >&2
echo "[ $(date -u) ]: LINEAGE_REPO_LOCATION: '${LINEAGE_REPO_LOCATION}'" >&2
echo "[ $(date -u) ]: ##### USER SETTINGS #####" >&2
echo "[ $(date -u) ]: query_filepath: '${query_filepath}'" >&2
echo "[ $(date -u) ]: output_filepath: '${output_filepath}'" >&2
echo "[ $(date -u) ]: evalue: '${evalue}'" >&2
echo "[ $(date -u) ]: max_target_seqs: '${max_target_seqs}'" >&2
echo "[ $(date -u) ]: threads: ${threads}" >&2
echo "[ $(date -u) ]: #########################" >&2

# Make tmp dir
mkdir ${output_tmpdir}
cd ${output_tmpdir}

# Set up the path to the blast db
echo "[BLAST]" > .ncbirc
echo "BLASTDB=\"${BLASTDB}\"" >> .ncbirc

# Run BLAST in parallel; idea from https://www.biostars.org/p/63816/ (accessed 190306)
echo "[ $(date -u) ]: Running BLAST on ${threads} threads (will take time)" >&2
cat "${query_filepath}" | \
  parallel -q -j ${threads} -k --block 1k --recstart '>' --pipe \
  blastp -db ${DB_NAME} -query - -evalue ${evalue} -max_target_seqs ${max_target_seqs} -num_threads 1 \
  -outfmt "6 qseqid sseqid pident evalue qcovhsp bitscore staxid ssciname stitle" > \
  ${output_basepath}_raw.tsv

# Add header
echo "[ $(date -u) ]: Performing intermediate file prep" >&2
sed -i '1 i\qseqid\tsseqid\tpident\tevalue\tqcovhsp\tbitscore\tstaxid\tssciname\tstitle' ${output_basepath}_raw.tsv

# Get full taxonomic lineage (beta code from C. Titus Brown's group)
## Get accession number
tail -n +2 ${output_basepath}_raw.tsv | cut -d $'\t' -f 2 | cut -d '|' -f 4 > ${output_basepath}_taxids.tmp.1
## Get taxid
tail -n +2 ${output_basepath}_raw.tsv | cut -d $'\t' -f 7 > ${output_basepath}_taxids.tmp.2
## Combine into CSV
paste -d ',' ${output_basepath}_taxids.tmp.1 ${output_basepath}_taxids.tmp.2 > ${output_basepath}_taxids.csv
rm ${output_basepath}_taxids.tmp.1 ${output_basepath}_taxids.tmp.2

# Run the lineage code
echo "[ $(date -u) ]: Getting NCBI linages (don't be surprised if a small number of errors are printed below; usually a few taxid's don't match the taxdump)" >&2
${LINEAGE_REPO_LOCATION}/make-lineage-csv.py \
  ${TAXDUMP_LOCATION}/nodes.dmp \
  ${TAXDUMP_LOCATION}/names.dmp \
  ${output_basepath}_taxids.csv \
  -o ${output_basepath}_lineages.csv 2>&1 | \
  tee ${output_basepath}_lineage_assignment.log

cat ${output_basepath}_lineages.csv | tr "," $'\t' > ${output_basepath}_lineages.tsv

rm ${output_basepath}_taxids.csv \
  ${output_basepath}_lineage_assignment.log \
  ${output_basepath}_lineages.csv

# Note that a few taxid's seem to not match most of the time. I think this must be due to the taxdump and the blast taxonomy info not being 100% in sync

# Confirm the results still match
echo "[ $(date -u) ]: Checking and combining outputs" >&2
tail -n +2 ${output_basepath}_raw.tsv | cut -d $'\t' -f 2 | cut -d '|' -f 4 > ${output_basepath}_taxids.tmp.3
tail -n +2 ${output_basepath}_lineages.tsv | cut -d $'\t' -f 1 > ${output_basepath}_taxids.tmp.4
output_status=$(cmp ${output_basepath}_taxids.tmp.3 ${output_basepath}_taxids.tmp.4 </dev/null; echo $?)
if [ ${output_status} != 0 ]; then
  echo "[ $(date -u) ]: ERROR: lineages table does not match the order of the original BLAST results. Cannot continue. Exiting..." >&2
  exit 1
fi

# Clean up
rm ${output_basepath}_taxids.tmp.3 ${output_basepath}_taxids.tmp.4

# Combine the tables
echo "[ $(date -u) ]: Writing output" >&2
cut -d $'\t' -f 3- ${output_basepath}_lineages.tsv | paste -d $'\t' ${output_basepath}_raw.tsv /dev/stdin > ${output_filepath}

# Clean up
rm ${output_basepath}_lineages.tsv \
  ${output_basepath}_raw.tsv \
  .ncbirc
rmdir ${output_tmpdir} # will throw an error if any extra files are still left in the folder

echo "[ $(date -u) ]: ${SCRIPT_NAME}: finished." >&2
