set -euo pipefail
# download_NCBI_genomes.sh
# Copyright Jackson M. Tsuji, 2023
# Iteratively pull genomes from NCBI that match search queries

# Startup processes
VERSION=$(basic-sequence-analysis-version)
script_name=${0##*/}
script_name=${script_name%.*}

# If no input is provided, provide help and exit
if [ $# -lt 2 ]; then

  # Help statement
  printf "${script_name}: pull genome data from NCBI.\n"
  printf "Copyright Jackson M. Tsuji, 2023\n"
  printf "Version: ${VERSION}\n"
  printf "Contact Jackson M. Tsuji (jackson.tsuji@lowtem.hokudai.ac.jp) for bug reports or feature requests.\n\n"
  printf "Installation: Requires NCBI entrez-direct as a dependency. Can install via conda by: 'conda create -n eutils -c bioconda entrez-direct'.\n\n"
  printf "Usage: ${0##*/} [OPTIONS] input_filepath output_directory\n\n"
  printf "Positional arguments:\n"
  printf "   1. input_filepath: Path to the file containing your queries. This can either be a simple list of queries separated by new lines or a tab-separated table where the query is in the first column, with no header. Queries can include GCA accessions (e.g., 'GCA_000168715.1'), strain IDs (e.g., 'DSM 13031'), organism taxonomy (e.g., 'Chlorobium')... really, anything you want. Will pull all genome assembly matches.\n"
  printf "   2. output_directory: Path to the directory where the genome phylogeny will be built. For safety, the script will not run if the directory already exists.\n\n"
  printf "Options (optional):\n"
  printf "   -e   filter_element (character, NCBI DocumentSummary element): Filter the hits by partial matches of the query to a particular element in the NCBI DocumentSummary (e.g., SpeciesName). You need to know the exact wording of the NCBI document summary element.) [Default: False]\n"
  printf "              To see an example Document Summary, run: 'esearch -query GCF_000168715.1 -db assembly | efetch -format docsum'\n"
  printf "   -f   force_override (False/True): Force to use the output folder, even if it already exists? (Existing files with same names as output will be overwritten.) [Default: False]\n"
  printf "   -i   info_only (False/True): Don't actually download the genomes; only pull the genome info and save it to a table. [Default: False]\n\n"

  printf "Example usages:\n"
  printf "   1. Suppose you want to download the genomes of 5 species but only have their strain identifiers (e.g., DSM 13031).\n"
  printf "            Make a list of the five strain IDs in a text file (e.g., strains.list), then run:\n"
  printf "                ${0##*/} strains.list strains_downloaded\n"
  printf "   2. Suppose you want to know all available genomes in a particular genus (e.g., Chlorobium).\n"
  printf "            Make a list with the name of the genus (e.g., genus.list), then run:\n"
  printf "                ${0##*/} -i True genus.list genus_downloaded\n"
  printf "            (The -i True flag is if you just want to see the results in a table but not download)\n\n"
  printf "            You could be more specific by only having your query match the SpeciesName element in the NCBI database:\n"
  printf "                ${0##*/} -e SpeciesName -i True genus.list genus_downloaded\n\n"

  printf "Output:\n"
  printf "   - For every run, 'genome_info.log' and 'genome_info.tsv' are created in the output folder with details about the search results.\n"
  printf "   - If you download genomes, the following are downloaded:\n"
  printf "       - Contigs (.fna.gz)\n"
  printf "       - Genes (.ffn.gz)\n"
  printf "       - Predicted ORFs (.faa.gz)\n"
  printf "       - RNA genes (.ffn.rna.gz)\n"
  printf "       - Genome Flat File (position information; .gff.gz)\n"
  printf "   - By default, the RefSeq genome entry is downloaded in favour of the GenBank entry, if a RefSeq entry exists.\n"
  printf "   - Some GenBank entries are missing a few of the files above. They will not be downloaded, in that case, and a warning will appear in the log.\n\n"

  # Exit
  exit 1

fi

# Set defaults for options
filter_element="False"
force_override="False"
info_only="False"

# Set options (help from https://wiki.bash-hackers.org/howto/getopts_tutorial; accessed March 8th, 2019)
OPTIND=1 # reset the OPTIND counter just in case
while getopts ":e:f:i:" opt; do
  case ${opt} in
    e)
      filter_element=${OPTARG}
      ;;
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
failed_downloads_filepath="${output_directory}/tmp/failed_downloads.tmp"

# Initialize logfile
mkdir -p "${output_directory}/tmp"
printf "" > ${log_filepath}

# Startup info
(>&2 echo "[ $(date -u) ]: Running ${0##*/}") 2>&1 | tee -a ${log_filepath}
(>&2 echo "[ $(date -u) ]: Version: ${VERSION}") 2>&1 | tee -a ${log_filepath}
(>&2 echo "[ $(date -u) ]: Command: ${0##*/} ${original_arguments}") 2>&1 | tee -a ${log_filepath}
(>&2 echo "[ $(date -u) ]: #### SETTINGS ####") 2>&1 | tee -a ${log_filepath}
(>&2 echo "[ $(date -u) ]: input_filepath: ${input_filepath}") 2>&1 | tee -a ${log_filepath}
(>&2 echo "[ $(date -u) ]: output_directory: ${output_directory}") 2>&1 | tee -a ${log_filepath}
(>&2 echo "[ $(date -u) ]: filter_element: ${filter_element}") 2>&1 | tee -a ${log_filepath}
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
printf "query\torganism\tspecies\tisolate\tassembly_accession\tassembly_name\tdatabase\tncbi_ftp_link\n" > ${output_table_filepath}

# Set a variable to know if any downloads failed
echo "0" > ${failed_downloads_filepath}

for query in ${queries[@]}; do

  # Search for the assembly document summary for the organism(s) matching the query.
  # NOTE: if there are multiple assemblies that match the search, will get multiple documents' worth of data.	
  (>&2 printf "[ $(date -u) ]: Searching for '${query}'") 2>&1 | tee -a ${log_filepath}
  esearch -query "${query}" -db assembly | efetch -format docsum > "${output_directory}/tmp/query_hit.tmp"
  	
  # Will be empty if the search failed
  if [ $(cat "${output_directory}/tmp/query_hit.tmp" | wc -m) -lt 10 ]; then
    (>&2 printf ": Found no search hits to '${query}'\n") 2>&1 | tee -a ${log_filepath}
    rm "${output_directory}/tmp/query_hit.tmp"
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
  tail -n +5 ${output_directory}/tmp/query_hit.tmp | head -n -2 > ${output_directory}/tmp/query_hit.tmp.trunc
  # TODO - is it always this exact number of lines?

  # Each document starts with <DocumentSummary> and ends with </DocumentSummary>
  # First, figure out where each file starts
  file_start_lines=($(grep -n "<DocumentSummary>" ${output_directory}/tmp/query_hit.tmp.trunc | cut -d ":" -f 1))
  number_of_hits=${#file_start_lines[@]}
  # Also figure out the last line of the file (and add one so that it looks like another starting line)
  last_line=$(cat ${output_directory}/tmp/query_hit.tmp.trunc | wc -l)
  last_line=$((${last_line}+1))
  # Put together into the same array
  file_start_lines=($(echo ${file_start_lines[@]} | tr ' ' $'\n' && echo ${last_line}))

  if [ ${filter_element} != "False" ]; then
    (>&2 printf ": Found ${number_of_hits} matching assemblies BEFORE filtration (see below)\n") 2>&1 | tee -a ${log_filepath}
  else
    (>&2 printf ": Found ${number_of_hits} matching assemblies\n") 2>&1 | tee -a ${log_filepath}
  fi

  # Now separate the file
  for i in $(seq 1 $((${#file_start_lines[@]}-1))); do
    j=$((${i}-1))
    k=${i}
    file_start_line=${file_start_lines[${j}]}
    file_end_line=$((${file_start_lines[${k}]}-1)) # The start line of the next entry, minus 1
    file_length=$((${file_end_line}-${file_start_line}+1))
    head -n ${file_end_line} ${output_directory}/tmp/query_hit.tmp.trunc | tail -n ${file_length} > ${output_directory}/tmp/query_hit.tmp.${i}
  done
  rm "${output_directory}/tmp/query_hit.tmp" "${output_directory}/tmp/query_hit.tmp.trunc"

  skipped_entries=0
  no_URL_entries=0
  # Now extract the data and download the sequences
  for i in $(seq 1 ${number_of_hits}); do

    # Make alternative zero-ordered counter
    j=$((${i}-1))
	
    query_file="${output_directory}/tmp/query_hit.tmp.${i}"

    if [ ${filter_element} != "False" ]; then
      # Filter the results by an additional optional filter criterion for the query
      # If the element does not contain the grep query, then
      if ! cat ${query_file} | xtract -pattern ${filter_element} -element ${filter_element} | grep -q "${query}"; then
        # Don't work with this entry; does not match filter criteria. Skip.
        skipped_entries=$((${skipped_entries}+1))
        continue
      fi
    fi

    # Parse important info out of the results page. Should only be one entry each.
    # TODO - consider checking for entry length to confirm
    organism=($(cat ${query_file} | xtract -pattern Organism -element Organism))
    species=($(cat ${query_file} | xtract -pattern SpeciesName -element SpeciesName))
    isolate=($(cat ${query_file} | xtract -pattern Isolate -element Isolate))
    assembly_name=($(cat ${query_file} | xtract -pattern AssemblyName -element AssemblyName))

    # Get RefSeq if present but GenBank otherwise
    if [ $(cat ${query_file} | xtract -pattern FtpPath_RefSeq -element FtpPath_RefSeq | wc -m) -lt 2 ]; then
      download_db="GenBank"
      accession=($(cat ${query_file} | xtract -pattern Genbank -element Genbank))

      # Also check if GenBank FTP path is there (sometimes it is removed if the entry was suppressed)
      if [ $(cat ${query_file} | xtract -pattern FtpPath_GenBank -element FtpPath_GenBank | wc -m) -lt 2 ]; then
        (>&2 printf "[ $(date -u) ]: WARNING: '${accession}' ('${organism}'; ${download_db}) ") 2>&1 | tee -a ${log_filepath}
        (>&2 printf "had no available URL for download. Skipping.\n") 2>&1 | tee -a ${log_filepath}
        no_URL_entries=$((${no_URL_entries}+1))
        continue
      else
        ftp_base=($(cat ${query_file} | xtract -pattern FtpPath_GenBank -element FtpPath_GenBank))
      fi

    else
      download_db="RefSeq"
      ftp_base=($(cat ${query_file} | xtract -pattern FtpPath_RefSeq -element FtpPath_RefSeq))
      accession=($(cat ${query_file} | xtract -pattern RefSeq -element RefSeq))
    fi
    rm ${query_file}

    # Add entry to table
    (>&2 printf "[ $(date -u) ]: '${accession}' ('${organism}'; ${download_db})") 2>&1 | tee -a ${log_filepath}
    # Use set +u to temporarily allow empty variables to be evaluated (i.e., in case non-important fields had no hit)
    set +u
    printf "${query}\t${organism}\t${species}\t${isolate}\t${accession}\t${assembly_name}\t${download_db}\t${ftp_base}\n" >> ${output_table_filepath}
    set -u

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
        ( failed_downloads=$(($(cat ${failed_downloads_filepath})+1)) && \
        echo ${failed_downloads} > ${failed_downloads_filepath} && \
        (>&2 echo "[ $(date -u) ]: FAILED to download '${outfile_path}.fna.gz'") 2>&1 | tee -a ${log_filepath} )
      wget -q -O - ${ftp_base}/${download_prefix}_cds_from_genomic.fna.gz > ${outfile_path}.ffn.gz || \
        ( failed_downloads=$(($(cat ${failed_downloads_filepath})+1)) && \
        echo ${failed_downloads} > ${failed_downloads_filepath} && \
        (>&2 echo "[ $(date -u) ]: FAILED to download '${outfile_path}.ffn.gz'") 2>&1 | tee -a ${log_filepath} )
      wget -q -O - ${ftp_base}/${download_prefix}_protein.faa.gz > ${outfile_path}.faa.gz || \
        ( failed_downloads=$(($(cat ${failed_downloads_filepath})+1)) && \
        echo ${failed_downloads} > ${failed_downloads_filepath} && \
        (>&2 echo "[ $(date -u) ]: FAILED to download '${outfile_path}.faa.gz'") 2>&1 | tee -a ${log_filepath} )
      wget -q -O - ${ftp_base}/${download_prefix}_rna_from_genomic.fna.gz > ${outfile_path}.ffn.rna.gz || \
        ( failed_downloads=$(($(cat ${failed_downloads_filepath})+1)) && \
        echo ${failed_downloads} > ${failed_downloads_filepath} && \
        (>&2 echo "[ $(date -u) ]: FAILED to download '${outfile_path}.ffn.rna.gz'") 2>&1 | tee -a ${log_filepath} )
      wget -q -O - ${ftp_base}/${download_prefix}_genomic.gff.gz > ${outfile_path}.gff.gz || \
        ( failed_downloads=$(($(cat ${failed_downloads_filepath})+1)) && \
        echo ${failed_downloads} > ${failed_downloads_filepath} && \
        (>&2 echo "[ $(date -u) ]: FAILED to download '${outfile_path}.gff.gz'") 2>&1 | tee -a ${log_filepath} )
      set -e

    else
      (>&2 printf "\n") 2>&1 | tee -a ${log_filepath} # Finish the log statement
    fi

  done

  if [ ${filter_element} != "False" ]; then
    (>&2 echo "[ $(date -u) ]: FINAL: got $((${number_of_hits}-${skipped_entries})) assemblies. Filtered ${skipped_entries} of the original hits due to not matching the '${filter_element}' element.") 2>&1 | tee -a ${log_filepath}
  fi

done

# Report if any downloads failed
failed_downloads=$(cat ${failed_downloads_filepath})
if [ ${failed_downloads} -gt 0 ]; then
  (>&2 echo "[ $(date -u) ]: WARNING: ${failed_downloads} file downloads FAILED. See log for details.") 2>&1 | tee -a ${log_filepath}
fi
if [ ${no_URL_entries} -gt 0 ]; then
  (>&2 echo "[ $(date -u) ]: WARNING: ${no_URL_entries} entries had no available URL for download and were skipped. See log for details.") 2>&1 | tee -a ${log_filepath}
fi

# Restore the old IFS
IFS=${IFS_backup}

# Delete tmp dir
rm -r "${output_directory}/tmp"

(>&2 echo "[ $(date -u) ]: ${0##*/}: Finished.") 2>&1 | tee -a ${log_filepath}
