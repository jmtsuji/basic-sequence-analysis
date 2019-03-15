# Tutorial: Creating whole genome phylogenies
Jackson M. Tsuji, 2019

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
```
GToTree_version="1.1.10"

mkdir -p ${HOME}/Installation_files
cd ${HOME}/Installation_files
curl -L https://github.com/AstrobioMike/GToTree/archive/v${GToTree_version}.tar.gz -o GToTree-v${GToTree_version}.tar.gz
tar -xzf GToTree-v${GToTree_version}.tar.gz
rm GToTree-v${GToTree_version}.tar.gz
cd GToTree-${GToTree_version}/
./conda-setup.sh
```

### Install Jackson's wrapper for GToTree
```
Jackson_script_version="1.1.1"

wget https://github.com/jmtsuji/basic-sequence-analysis/archive/v${Jackson_script_version}.tar.gz
tar -xzf v${Jackson_script_version}.tar.gz
rm v${Jackson_script_version}.tar.gz
cd basic-sequence-analysis-v${Jackson_script_version}
conda activate gtotree
cp phylogeny_builder_whole_genome.sh ${CONDA_PREFIX}/bin
cd ..
rm basic-sequence-analysis-v${Jackson_script_version}
```

### Important note
If you ever want to change your version of GToTree, you have to first remove the old version:
```
conda remove -y -n gtotree
```
Then, you can run the installation code above to make a new gtotree install


## Setup before running the genome script
- Choose a working directory (`photomic-workstation` server): e.g., `/home/setsuko/Analysis/2019_03_05_Aquabacterium_genome_tree`
- Copy the genomes of interest into `/home/setsuko/Analysis/2019_03_05_Aquabacterium_genome_tree/input_genomes`. Files should end with "*.fna"

## Made genome tree
```
# User settings
work_dir="/home/setsuko/Analysis/2019_03_05_Aquabacterium_genome_tree"
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
- Maximum likelihood phylogeny (unrooted; 1000 bootstraps)
- Log file for the phylogeny (IQ-TREE)
- Multiple sequence alignment used for the phylogeny
- Log file for identifying and aligning the ribosomal protein genes (GToTree)

HTML summary made via https://dillinger.io/

