set -euo pipefail
# download_NCBI_genomes.sh
# Copyright Jackson M. Tsuji, 2019
# Iteratively pull genomes from NCBI that match search queries

# Startup processes
VERSION=$(basic-sequence-analysis-version)
script_name=${0##*/}
script_name=${script_name%.*}

# If no input is provided, provide help and exit
if [ $# -lt 2 ]; then

	# Help statement
	printf "${script_name}: pull genome data from NCBI.\n"
	printf "Copyright Jackson M. Tsuji, Neufeld Research Group, 2019\n"
	printf "Version: ${VERSION}\n"
	printf "Contact Jackson M. Tsuji (jackson.tsuji@uwaterloo.ca) for bug reports or feature requests.\n\n"
	printf "Installation: Requires NCBI entrez-direct as a dependency. Can install via conda by: 'conda create -n eutils -c bioconda entrez-direct'.\n\n"
	printf "Usage: ${0##*/} [OPTIONS] input_filepath output_directory\n\n"
	printf "Positional arguments:\n"
	printf "   1. input_filepath: Path to the file containing your queries. This can either be a simple list of queries separated by new lines or a tab-separated table where the query is in the first column, with no header. Queries can include GCA accessions (e.g., 'GCA_000168715.1'), strain IDs (e.g., 'DSM 13031'), organism taxonomy (e.g., 'Chlorobium')... really, anything you want. Will pull all genome assembly matches.\n"
	printf "   2. output_directory: Path to the directory where the genome phylogeny will be built. For safety, the script will not run if the directory already exists.\n\n"
	printf "Options (optional):\n"
   	printf "   -f   force_override (False/True): Force to use the output folder, even if it already exists? (Existing files with same names as output will be overwritten.) [Default: False]\n"
   	printf "   -i   info_only (False/True): Don't actually download the genomes; only pull the genome info and save it to a table. [Default: False]\n"

	# Exit
	exit 1

fi

# Set defaults for options
force_override="False"
info_only="False"

# Set options (help from https://wiki.bash-hackers.org/howto/getopts_tutorial; accessed March 8th, 2019)
OPTIND=1 # reset the OPTIND counter just in case
while getopts ":f:i:" opt; do
	case ${opt} in
		f)
			force_override=${OPTARG}
			;;
		i)
			info_only=${OPTARG}
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
output_directory=$2

# Check if inputs are valid
if [ ${force_override} != "True" -a ${force_override} != "False" ]; then
    (>&2 echo "[ $(date -u) ]: ERROR: force_override must be either 'True' or 'False', but '${force_override}' was supplied. Exiting...")
    exit 1
fi
if [ ${info_only} != "True" -a ${info_only} != "False" ]; then
    (>&2 echo "[ $(date -u) ]: ERROR: info_only must be either 'True' or 'False', but '${info_only}' was supplied. Exiting...")
    exit 1
fi

# Check if the output directory exists
if [ ${force_override} = "False" ]; then
	if [ -d ${output_directory} ]; then
		(>&2 echo "[ $(date -u) ]: ERROR: output_directory '${output_directory}' already exists. Please delete it before running this script, or set force_override to 'True'. Exiting...")
		exit 1
	fi
fi

# Set script-determined variables
output_table_filepath="${output_directory}/genome_info.tsv"
log_filepath="${output_directory}/genome_info.log"

# Initialize logfile
mkdir -p "${output_directory}"
printf "" > ${log_filepath}

# Startup info
(>&2 echo "[ $(date -u) ]: Running ${0##*/}") 2>&1 | tee -a ${log_filepath}
(>&2 echo "[ $(date -u) ]: Version: ${VERSION}") 2>&1 | tee -a ${log_filepath}
(>&2 echo "[ $(date -u) ]: Command: ${0##*/} ${original_arguments}") 2>&1 | tee -a ${log_filepath}
(>&2 echo "[ $(date -u) ]: #### SETTINGS ####") 2>&1 | tee -a ${log_filepath}
(>&2 echo "[ $(date -u) ]: input_filepath: ${input_filepath}") 2>&1 | tee -a ${log_filepath}
(>&2 echo "[ $(date -u) ]: output_directory: ${output_directory}") 2>&1 | tee -a ${log_filepath}
(>&2 echo "[ $(date -u) ]: force_override: ${force_override}") 2>&1 | tee -a ${log_filepath}
(>&2 echo "[ $(date -u) ]: info_only: ${info_only}") 2>&1 | tee -a ${log_filepath}
(>&2 echo "[ $(date -u) ]: ##################") 2>&1 | tee -a ${log_filepath}

# NOTE: For the search, temporarily change the 'internal field separator' (IFS) to allow for spaces in the queries and results
IFS_backup=${IFS}
IFS=$'\n' # Only separate between queries when hitting a line space

# Load queries from input file
queries=($(cut -d $'\t' -f 1 ${input_filepath}))

(>&2 echo "[ $(date -u) ]: Found '${#queries[@]}' queries to search") 2>&1 | tee -a ${log_filepath}

# Initialize information table
printf "query\torganism\tspecies\tisolate\tassembly_accession\tassembly_name\tdatabase\tgenbank_ftp_link\n" > ${output_table_filepath}

# Set a variable to know if any downloads failed
failed_downloads=0

for query in ${queries[@]}; do

	# Search for the assembly document summary for the organism(s) matching the query.
	# NOTE: if there are multiple assemblies that match the search, will get multiple documents' worth of data.	
	(>&2 printf "[ $(date -u) ]: Searching for '${query}'") 2>&1 | tee -a ${log_filepath}
	esearch -query "${query}" -db assembly | efetch -format docsum > "${output_directory}/query_hit.tmp"
		
	# Will be empty if the search failed
	if [ $(cat "${output_directory}/query_hit.tmp" | wc -m) -lt 10 ]; then
	    (>&2 printf ": Found no search hits to '${query}'\n") 2>&1 | tee -a ${log_filepath}
	    rm "${output_directory}/query_hit.tmp"
    	continue # Doesn't finish the loop
	fi
	
	## Separate by hit
	# Whole file starts with:
	# <?xml version="1.0" encoding="UTF-8" ?>
	# <!DOCTYPE DocumentSummarySet PUBLIC "-//NLM//DTD esummary assembly 20180216//EN" "https://eutils.ncbi.nlm.nih.gov/eutils/dtd/20180216/esummary_assembly.dtd">
	# 
	# <DocumentSummarySet status="OK">
	# and ends with:
	# </DocumentSummarySet>
	#
	
	# So take off these chunks
	tail -n +5 ${output_directory}/query_hit.tmp | head -n -2 > ${output_directory}/query_hit.tmp.trunc
	# TODO - is it always this exact number of lines?
	
	# Each document starts with <DocumentSummary> and ends with </DocumentSummary>
	# First, figure out where each file starts
	file_start_lines=($(grep -n "<DocumentSummary>" ${output_directory}/query_hit.tmp.trunc | cut -d ":" -f 1))
	number_of_hits=${#file_start_lines[@]}
	# Also figure out the last line of the file (and add one so that it looks like another starting line)
	last_line=$(cat ${output_directory}/query_hit.tmp.trunc | wc -l)
	last_line=$((${last_line}+1))
	# Put together into the same array
	file_start_lines=($(echo ${file_start_lines[@]} | tr ' ' $'\n' && echo ${last_line}))
	
	(>&2 printf ": Found ${number_of_hits} matching assemblies\n") 2>&1 | tee -a ${log_filepath}
	
	# Now separate the file
	for i in $(seq 1 $((${#file_start_lines[@]}-1))); do
		j=$((${i}-1))
		k=${i}
		file_start_line=${file_start_lines[${j}]}
		file_end_line=$((${file_start_lines[${k}]}-1)) # The start line of the next entry, minus 1
		file_length=$((${file_end_line}-${file_start_line}+1))
		head -n ${file_end_line} ${output_directory}/query_hit.tmp.trunc | tail -n ${file_length} > ${output_directory}/query_hit.tmp.${i}
	done
	rm "${output_directory}/query_hit.tmp" "${output_directory}/query_hit.tmp.trunc"

	# Now extract the data and download the sequences
	for i in $(seq 1 ${number_of_hits}); do

		# Make alternative zero-ordered counter
		j=$((${i}-1))
		
		query_file="${output_directory}/query_hit.tmp.${i}"

		# Parse important info out of the results page. Should only be one entry each.
		# TODO - consider checking for entry length to confirm
		organism=($(cat ${query_file} | xtract -pattern DocumentSummary -element Organism))
		species=($(cat ${query_file} | xtract -pattern DocumentSummary -element SpeciesName))
		isolate=($(cat ${query_file} | xtract -pattern DocumentSummary -element Isolate))
		assembly_name=($(cat ${query_file} | xtract -pattern DocumentSummary -element AssemblyName))
		
		# Get RefSeq if present but GenBank otherwise
		if [ $(cat ${query_file} | xtract -pattern DocumentSummary -element FtpPath_RefSeq | wc -m) -lt 2 ]; then
		    download_db="GenBank"
		    ftp_base=($(cat ${query_file} | xtract -pattern DocumentSummary -element FtpPath_GenBank))
		    accession=($(cat ${query_file} | xtract -pattern DocumentSummary -element Genbank))
		else
            download_db="RefSeq"
		    ftp_base=($(cat ${query_file} | xtract -pattern DocumentSummary -element FtpPath_RefSeq))
		    accession=($(cat ${query_file} | xtract -pattern DocumentSummary -element RefSeq))
		fi
		rm ${query_file}

		# Add entry to table
        (>&2 printf "[ $(date -u) ]: '${accession}' ('${organism}'; ${download_db})") 2>&1 | tee -a ${log_filepath}
		printf "${query}\t${organism}\t${species}\t${isolate}\t${accession}\t${assembly_name}\t${download_db}\t${ftp_base}\n" >> ${output_table_filepath}
 
		## Notes - Using the RefSeq or GenBank FTP
		# E.g., if URL is: ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/168/715/GCF_000168715.1_ASM16871v1
		# (Note: the accession here is 'GCF_000168715.1', and the assembly name name is 'ASM16871v1')
		# Then here are URLs for the following types of data:
		# Contigs: ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/168/715/GCF_000168715.1_ASM16871v1/GCF_000168715.1_ASM16871v1_genomic.fna.gz
		# Genes: ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/168/715/GCF_000168715.1_ASM16871v1/GCF_000168715.1_ASM16871v1_cds_from_genomic.fna.gz
		# ORFs: ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/168/715/GCF_000168715.1_ASM16871v1/GCF_000168715.1_ASM16871v1_protein.faa.gz
		# RNA genes: ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/168/715/GCF_000168715.1_ASM16871v1/GCF_000168715.1_ASM16871v1_rna_from_genomic.fna.gz
		# Genome Flat File (GFF): ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/168/715/GCF_000168715.1_ASM16871v1/GCF_000168715.1_ASM16871v1_genomic.gff.gz

        if [ ${info_only} = "False" ]; then
			# Make a nice output filename
			species_cleaned=$(echo ${species} | sed "s/ \+/_/g" | sed "s/[[:punct:]]\+/_/g") # Replace odd punctuation with underscores
            outfile_name="${species_cleaned}__${accession}"
			outfile_path="${output_directory}/${outfile_name}"

			# Download
			# TODO - consider adding a method to only download some of these files if desired
    		(>&2 printf ": Downloading as '${outfile_name}' from '${ftp_base}'\n") 2>&1 | tee -a ${log_filepath}
			download_prefix=${ftp_base##*/}
			
			# For each URL, report to the user if it fails to download for some reason.
			set +e # Let the script keep going if one fails.
			wget -q -O - ${ftp_base}/${download_prefix}_genomic.fna.gz > ${outfile_path}.fna.gz || \
			    ( failed_downloads=$((${failed_downloads}+1)) && \
			    (>&2 echo "[ $(date -u) ]: FAILED to download '${outfile_path}.fna.gz'") 2>&1 | tee -a ${log_filepath} )
			wget -q -O - ${ftp_base}/${download_prefix}_cds_from_genomic.fna.gz > ${outfile_path}.ffn.gz || \
			    ( failed_downloads=$((${failed_downloads}+1)) && \
			    (>&2 echo "[ $(date -u) ]: FAILED to download '${outfile_path}.ffn.gz'") 2>&1 | tee -a ${log_filepath} )
			wget -q -O - ${ftp_base}/${download_prefix}_protein.faa.gz > ${outfile_path}.faa.gz || \
			    ( failed_downloads=$((${failed_downloads}+1)) && \
			    (>&2 echo "[ $(date -u) ]: FAILED to download '${outfile_path}.faa.gz'") 2>&1 | tee -a ${log_filepath} )
			wget -q -O - ${ftp_base}/${download_prefix}_rna_from_genomic.fna.gz > ${outfile_path}.ffn.rna.gz || \
			    ( failed_downloads=$((${failed_downloads}+1)) && \
			    (>&2 echo "[ $(date -u) ]: FAILED to download '${outfile_path}.ffn.rna.gz'") 2>&1 | tee -a ${log_filepath} )
			wget -q -O - ${ftp_base}/${download_prefix}_genomic.gff.gz > ${outfile_path}.gff.gz || \
			    ( failed_downloads=$((${failed_downloads}+1)) && \
			    (>&2 echo "[ $(date -u) ]: FAILED to download '${outfile_path}.gff.gz'") 2>&1 | tee -a ${log_filepath} )
			set -e
			
		else
		    (>&2 printf "\n") 2>&1 | tee -a ${log_filepath} # Finish the log statement
		fi

	done

done

# Restore the old IFS
IFS=${IFS_backup}

# Report if any downloads failed
if [ ${failed_downloads} -gt 0 ]; then
    (>&2 echo "[ $(date -u) ]: ${0##*/}: WARNING: ${failed_downloads} file downloads FAILED. See log for details.") 2>&1 | tee -a ${log_filepath}
fi

(>&2 echo "[ $(date -u) ]: ${0##*/}: Finished.") 2>&1 | tee -a ${log_filepath}
