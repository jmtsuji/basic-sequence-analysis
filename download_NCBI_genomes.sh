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
printf "query\torganism\tspecies\tassembly_accession\tassembly_name\tgenbank_ftp_link\n" > ${output_table_filepath}

for query in ${queries[@]}; do

	# Search for the assembly document summary for the organism(s) matching the query.
	# NOTE: if there are multiple assemblies that match the search, will get multiple documents' worth of data.	
	(>&2 echo "[ $(date -u) ]: Searching for '${query}'") 2>&1 | tee -a ${log_filepath}
	esearch -query "${query}" -db assembly | efetch -format docsum > "${output_directory}/query_hit.tmp"
		
	# Will be empty if the search failed
	if [ $(cat "${output_directory}/query_hit.tmp" | wc -m) = 1 ]; then
	    (>&2 echo "[ $(date -u) ]: Found no search hits to '${query}'") 2>&1 | tee -a ${log_filepath}
    	continue # Doesn't finish the loop
	fi
	
	# Parse important info out of the results page
	# TODO - will NOT WORK PROPERLY if any of the results are missing any of these entries!!
	organism=($(cat "${output_directory}/query_hit.tmp" | xtract -pattern DocumentSummary -element Organism))
	species=($(cat "${output_directory}/query_hit.tmp" | xtract -pattern DocumentSummary -element SpeciesName))
	accession=($(cat "${output_directory}/query_hit.tmp" | xtract -pattern DocumentSummary -element AssemblyAccession))
	assembly_name=($(cat "${output_directory}/query_hit.tmp" | xtract -pattern DocumentSummary -element AssemblyName))
	genbank_ftp_base=($(cat "${output_directory}/query_hit.tmp" | xtract -pattern DocumentSummary -element FtpPath_GenBank))
	rm "${output_directory}/query_hit.tmp"

	(>&2 echo "[ $(date -u) ]: Found ${#organism[@]} matching assemblies") 2>&1 | tee -a ${log_filepath}
	# TODO - confirm that the # of entries for each pulled element above are the same

	# Now download the sequences
	for i in $(seq 1 ${#organism[@]}); do

		# Set counter to zero-ordered
		j=$((${i}-1))

		# Get variables
		organism_single=${organism[${j}]}
		species_single=${species[${j}]}
		accession_single=${accession[${j}]}
		assembly_name_single=${assembly_name[${j}]}
		genbank_ftp_base_single=${genbank_ftp_base[${j}]}

		# Add entry to table
        (>&2 printf "[ $(date -u) ]: '${accession_single}' ('${organism_single}')") 2>&1 | tee -a ${log_filepath}
		printf "${query}\t${organism_single}\t${species_single}\t${accession_single}\t${assembly_name_single}\t${genbank_ftp_base_single}\n" >> ${output_table_filepath}
 
		## Notes - Using the RefSeq FTP
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
			species_cleaned=$(echo ${species_single} | sed "s/ \+/_/g" | sed "s/[[:punct:]]\+/_/g") # Replace odd punctuation with underscores
            outfile_name="${species_cleaned}__${accession_single}"
			outfile_path="${output_directory}/${outfile_name}"

			# Download
			# TODO - set way to only download some of these files if desired
    		(>&2 printf ": Downloading as '${outfile_name}' from '${genbank_ftp_base_single}'\n") 2>&1 | tee -a ${log_filepath}
			genbank_prefix=${genbank_ftp_base##*/}
			wget -q -O - ${genbank_ftp_base}/${genbank_prefix}_genomic.fna.gz > ${outfile_path}.fna.gz
			wget -q -O - ${genbank_ftp_base}/${genbank_prefix}_cds_from_genomic.fna.gz > ${outfile_path}.ffn.gz
			wget -q -O - ${genbank_ftp_base}/${genbank_prefix}_protein.faa.gz > ${outfile_path}.faa.gz
			wget -q -O - ${genbank_ftp_base}/${genbank_prefix}_rna_from_genomic.fna.gz > ${outfile_path}.ffn.rna.gz
			wget -q -O - ${genbank_ftp_base}/${genbank_prefix}_genomic.gff.gz > ${outfile_path}.gff.gz
			
		else
		    (>&2 printf "\n") 2>&1 | tee -a ${log_filepath} # Finish the log statement
		fi

	done

done

# Restore the old IFS
IFS=${IFS_backup}

(>&2 echo "[ $(date -u) ]: ${0##*/}: Finished.") 2>&1 | tee -a ${log_filepath}
