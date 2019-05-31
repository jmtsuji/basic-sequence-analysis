set -euo pipefail
# test_download_NCBI_genomes.sh
# Runs automated test for download_NCBI_genomes.sh

# Startup processes
VERSION=$(basic-sequence-analysis-version)
script_name=${0##*/}
script_name=${script_name%.*}

# If no input is provided, provide help and exit
if [ $# -lt 1 ]; then

	# Help statement
	printf "${script_name}: runs end-to-end test for download_NCBI_genomes.sh.\n"
	printf "Copyright Jackson M. Tsuji, Neufeld Research Group, 2019\n"
	printf "Version: ${VERSION}\n"
	printf "Contact Jackson M. Tsuji (jackson.tsuji@uwaterloo.ca) for bug reports or feature requests.\n\n"
	printf "Installation: Requires NCBI entrez-direct as a dependency. Can install via conda by: 'conda create -n eutils -c bioconda entrez-direct'.\n\n"
	printf "Usage: ${0##*/} test_directory\n\n"
	printf "Positional arguments:\n"
	printf "   1. test_directory: path to the base test directory containing 'test_input.list' and the 'expected_output' subfolder with expected MD5s\n"

	# Exit
	exit 1

fi

# Set variables
test_directory=$1

# TODO - confirm test_directory exists
cd ${test_directory}

# TODO - confirm test_output does not already exist
echo "[ $(date -u) )]: Performing test run in '${test_directory}'"
echo "[ $(date -u) )]: download_NCBI_genomes.sh -i True test_input.list test_output 2&>/dev/null"
download_NCBI_genomes.sh -i True test_input.list test_output 2&>/dev/null

######
## NOTE: To prepare md5sum test dataset for the first time
# cp -r test_output expected_output
# cut -d "]" -f 2- expected_output/genome_info.log | grep -v "Version: " > expected_output/genome_info.log.cut # Get rid of timestamp and version
# md5sum expected_output/genome_info.log.cut > expected_output/genome_info.log.cut.md5
# md5sum expected_output/genome_info.tsv > expected_output/genome_info.tsv.md5

# Test the output
cut -d "]" -f 2- test_output/genome_info.log | grep -v "Version: " > test_output/genome_info.log.cut # Get rid of timestamp and version
log_md5_test=$(md5sum test_output/genome_info.log.cut | cut -d " "  -f 1)
tsv_md5_test=$(md5sum test_output/genome_info.tsv | cut -d " "  -f 1)

test_result=0

if [ $(echo ${log_md5_test}) != $(cut -d " " -f 1 expected_output/genome_info.log.cut.md5) ]; then
	echo "[ $(date -u) )]: FAILED: Log files don't match"
	test_result=1
else
	echo "[ $(date -u) )]: PASSED: Log files match"
fi

if [ $(echo ${tsv_md5_test}) != $(cut -d " " -f 1 expected_output/genome_info.tsv.md5) ]; then
	echo "[ $(date -u) )]: FAILED: TSV files don't match"
	test_result=1
else
	echo "[ $(date -u) )]: PASSED: TSV files match"
fi

# Final reporting
if [ ${test_result} = 0 ]; then

	echo "[ $(date -u) )]: All tests passed."
	
	# Cleanup
	rm -r test_output
	
elif [ ${test_result} = 1 ]; then
	echo "[ $(date -u) )]: At least one test FAILED (see above). Not cleaning up test output directory 'test_output' so that you can debug."
fi
