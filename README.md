# basic-sequence-analysis
Simple scripts to perform basic FastX file manipulations

Copyright Jackson M. Tsuji, 2022

## Dependencies:
- All scripts require the `basic-sequence-analysis-version` helper script to run
- A few scripts have additional dependencies (e.g., `seqtk`, `bbmap`, and so on). This is mentioned in the help statement of each script.

## Usage
See the help statement at the start of each script by running the script. Many of the simpler ones support STDIN/STDOUT.

## What's included?
### Scripts (quick descriptions; see help files for more)
- `check_md5_hashes.sh`: tests if .fastq.gz files have the same MD5 hash as downloaded (e.g., from a webserver)
- `download_NCBI_genomes.sh`: downloads genomes from NCBI given a list of search queries
- `fasta_dealign.sh`: dealigns fastA file
- `fasta_U_T_swap.sh`: converts between U's and T's in FastA files
- `fastq_get_names.sh`: grab names from FastQ file
- `fastx_subset.sh`: subset a batch of FastX files (FastA/FastQ) to a given number or proportion of reads
- `phylogeny_builder_16S_rRNA.sh`: build a 16S rRNA gene tree subsetted to a particular part of the 16S gene, starting from unaligned sequences
- `seq_name_simplify.sh`: removes special characters and such from FastA files
- `text_find_and_replace.sh`: Find and replace specific text entries in an input text file
- `predict_short_orfs.sh`: Predict open reading frames (ORFs) from short read metagenome data by wrapping bbmap's reformat.sh and FGS++

## Supporting files
- `test_data`: for testing some of the scripts. Still in progress.
- `tutorials`: explaining how to install/use the more complex scripts. Still in progress.

## Final note
These scripts are 'quick and dirty' and do not carefully check user input, so be careful to follow the usage instructions carefully or look at the code to see how the tools work (workflow is very straightforward for most). Please let me know if you have questions or run into issues.
