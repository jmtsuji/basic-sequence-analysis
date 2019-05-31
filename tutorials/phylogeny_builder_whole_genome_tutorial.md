# Tutorial: Creating whole genome phylogenies via `phylogeny_builder_whole_genome.sh`
Jackson M. Tsuji, Neufeld Research Group, 2019

## Setup
### Install conda (general software manager), if you have not already done so
```
cd ${HOME}/Downloads
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
chmod 755 Miniconda3-latest-Linux-x86_64.sh
./Miniconda3-latest-Linux-x86_64.sh # Followed the prompts
rm Miniconda3-latest-Linux-x86_64.sh
```
miniconda3 is now installed, based at `${HOME}/miniconda3`

## Install GToTree and a convenient wrapper script
### Install GToTree
Simple version (beginner users)
```
GToTree_version="1.1.10"

mkdir -p ${HOME}/Installation_files
cd ${HOME}/Installation_files
wget -nv -O - https://github.com/AstrobioMike/GToTree/archive/v${GToTree_version}.tar.gz > GToTree-v${GToTree_version}.tar.gz
tar -xzf GToTree-v${GToTree_version}.tar.gz
rm GToTree-v${GToTree_version}.tar.gz
cd GToTree-${GToTree_version}/
./conda-setup.sh
```
Note that this installation *requires* that you keep the GToTree folder in `${HOME}/Installation_files`. If you delete this folder, GToTree will no longer work!

Advanced install (allows for multiple parallel versions of GToTree to be installed simultaneously and keeps all files in the conda env)
```
GToTree_version="1.1.10"

# Download the repo
cd /tmp
wget -nv -O - https://github.com/AstrobioMike/GToTree/archive/v${GToTree_version}.tar.gz > GToTree-v${GToTree_version}.tar.gz
tar -xzf GToTree-v${GToTree_version}.tar.gz
rm GToTree-v${GToTree_version}.tar.gz
cd GToTree-${GToTree_version}

# Create the conda env
conda create -n gtotree_${GToTree_version} -y -c bioconda -c conda-forge -c au-eoed biopython hmmer=3.2.1 muscle=3.8.1551 trimal=1.4.1 fasttree=2.1.10 iqtree=1.6.9 prodigal=2.6.3 taxonkit=0.3.0 gnu-parallel=20161122

# Activate the env
conda activate gtotree_${GToTree_version}

# Copy needed parts into the env
cp bin/* ${CONDA_PREFIX}/bin
mkdir -p ${CONDA_PREFIX}/db
cp -r hmm_sets test_data ${CONDA_PREFIX}/db

# Add env settings
mkdir -p ${CONDA_PREFIX}/etc/conda/activate.d
env_settings_filepath="${CONDA_PREFIX}/etc/conda/activate.d/env_vars.sh"
echo '#!/bin/sh' > ${env_settings_filepath}
echo "export GToTree_HMM_dir=${CONDA_PREFIX}/db/hmm_sets" >> ${env_settings_filepath}

# Download NCBI tax database
mkdir -p ${CONDA_PREFIX}/db/ncbi_tax_info
cd ${CONDA_PREFIX}/db/ncbi_tax_info
curl --silent --retry 10 -O ftp://ftp.ncbi.nih.gov/pub/taxonomy/taxdump.tar.gz
tar -xzf taxdump.tar.gz
rm taxdump.tar.gz
echo "export TAXONKIT_DB=${CONDA_PREFIX}/db/ncbi_tax_info" >> ${env_settings_filepath}

# Add localization variables
echo 'export LC_ALL="en_US.UTF-8"' >> ${env_settings_filepath}
echo 'export LANG="en_US.UTF-8"' >> ${env_settings_filepath}

# Agree to cite parallel
printf "will cite" | parallel --citation 2&> /dev/null

# Re-start the environment
conda activate gtotree_${GToTree_version}

# Test GToTree
test_dir="${CONDA_PREFIX}/db/test_data"
cd ${test_dir}
GToTree -a ${test_dir}/ncbi_accessions.txt -g ${test_dir}/genbank_files.txt -f ${test_dir}/fasta_files.txt \
    -A ${test_dir}/amino_acid_files.txt -H Bacteria -m ${test_dir}/genome_to_id_map.tsv -t -j 4 -o GToTree_test
# Check if the results look good
# Then delete the test folder
gtt-clean-after-test.sh
```

### Install this repo's wrapper for GToTree
```
basic_sequence_analysis_version="1.3.0"
conda activate gtotree # Note that 'gtotree_${GToTree_version}' is needed is you used the advance install method

cd /tmp
wget https://github.com/jmtsuji/basic-sequence-analysis/archive/v${basic_sequence_analysis_version}.tar.gz
tar -xzf v${basic_sequence_analysis_version}.tar.gz
rm v${basic_sequence_analysis_version}.tar.gz
cd basic-sequence-analysis-${basic_sequence_analysis_version}
cp phylogeny_builder_whole_genome.sh basic-sequence-analysis-version ${CONDA_PREFIX}/bin
cd ..
rm -rf basic-sequence-analysis-${basic_sequence_analysis_version}
```

## Setup before running the genome script
- Choose a working directory on your server, `/home/jmtsuji/Analysis/2019_03_05_genome_tree`
- Copy the genomes of interest into `/home/jmtsuji/Analysis/2019_03_05_genome_tree/input_genomes`. Nucleotide files should end with `.fna` or `.fna.gz`. Amino acid files should end with `.faa` or `.faa.gz`

## Make genome tree
```
# User settings
work_dir="/home/jmtsuji/Analysis/2019_03_05_genome_tree"
genome_dir=${work_dir}/input_genomes
output_dir=${work_dir}/output_vs1
log_name="phylogeny_builder_whole_genome_vs1.log"
threads=24
bootstrap_replicates=1000
bootstrap_type="normal"
phylogenetic_model="Universal_Hug_et_al.hmm" # run `gtt-hmms` to see all available models

# Run the script
cd ${work_dir}
phylogeny_builder_whole_genome.sh -@ ${threads} -b ${bootstrap_replicates} \
    -B ${bootstrap_type} -p ${phylogenetic_model} \
    ${genome_dir} ${output_dir} 2>&1 | tee ${log_name}
# Note: to see the other options you can change, run `phylogeny_builder_whole_genome.sh`.
```

## Summary
### Key programs used
- GToTree
- IQ-TREE
- For a list of all programs, run `conda list` inside of the gtotree conda environment

### Final output files in the 'summary' folder
- Maximum likelihood phylogeny (unrooted)
- Log file for the phylogeny (IQ-TREE)
- Multiple sequence alignment used for the phylogeny
- Log file for identifying and aligning the ribosomal protein genes (GToTree)

HTML summary made via https://dillinger.io/

