
> Under development!

# Metformin virome

Snakemake workflow for virome quantitation in Metformin treated T2D patients using assembled metagenomes.

## Bioproject datasets

### PRJNA361402 data

PRJNA361402 [[1]](#1) data was analysed separately, 40 T2D patients from Spain.

### PRJEB1786 data

PRJEB1786 gut metagenome in European women with normal, impaired and diabetic glucose control data [[2]](#2) and [[3]](#3). Faecal metagenome of 53 T2D patients and 43 subjects with normal glucose tolerance (NGT) from Sweden. All study participants were female. 70-year-old women were included if they had T2D, IGT or NGT. Exclusion criteria were chronic inflammatory disease and treatment with antibiotics during the preceding 3 months. An average of 3.1 +/- 1.8 Gb of PE reads for each sample.

### PRJEB5224 data

PRJEB5224 data [[4]](#4) gut microbiome of 75 T2D patients from Denmark.

## Setup environment and install prerequisites

### Install miniconda

Download and install miniconda https://conda.io/docs/user-guide/install/index.html.
In case of Linux, following should work:
```
wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh
```

### Install environment

Create conda environment with **snakemake**. 
There are two options:

To upload results to [Zenodo](zenodo.org), you need snakemake Zenodo remote provider, which is currently implemented in *zenodo-simple* branch in my forked snakemake repo. 

First, clone snakemake repo and checkout *zenodo-simple* branch:
```
git clone https://tpall@bitbucket.org/tpall/snakemake.git
cd snakemake
git checkout zenodo-simple
```

Then, create conda environment, install prerequisites and snakemake:
```
conda env create -f environment.yml -n snakemake
source activate snakemake
pip install -e .
```

### Setup databases
Together all databases will occupy ~250GB+ from your HD. 

#### BLAST databases

1. Download BLAST version 5 databases

Download version 5 BLAST databases using these instructions https://ftp.ncbi.nlm.nih.gov/blast/db/v5/blastdbv5.pdf

Briefly, you can use `update_blastdb.pl` script from BLAST+ software bundle to update/download BLAST databases.

To get BLAST, you can start by creating conda environment with blast+ like so:

```
conda env create -n blastenv
conda blastenv activate
conda install -c bioconda blast
```

Change working directory to location where you want BLAST databases to be installed, e.g. `$HOME/databases/blast`. 
```
mkdir -p $HOME/databases/blast
cd $HOME/databases/blast
```

Use update_blastdb.pl (included with the BLAST+ package) to check available version 5 databases, use the --blastdb_version flag:
```
update_blastdb.pl --blastdb_version 5 --showall
```

Download nt_v5 and nr_v5 databases (takes time and might need restarting if connection drops):
```
update_blastdb.pl --blastdb_version 5 nt_v5 --decompress
update_blastdb.pl --blastdb_version 5 nr_v5 --decompress
```

2. Setup BLASTDB environment variable
Edit $HOME/.bashrc file to permanently add BLASTDB variable to your shell environment
```
echo 'export BLASTDB=$HOME/databases/blast' >> $HOME/.bashrc
source $HOME/.bashrc
echo $BLASTDB
```

#### Download reference genome databases

1. Human reference genome.

First, create a directory for the reference genome sequence file, e.g `mkdir -p $HOME/databases/ref_genomes && cd $HOME/databases/ref_genomes`.

Then, human refgenome human_g1k_v37.fasta.gz sequences file can be obtained like so:
```
wget --continue ftp://ftp.ncbi.nlm.nih.gov/1000genomes/ftp/technical/reference/human_g1k_v37.fasta.gz
```
2. Bacterial reference genome sequences.

Create a directory for the bacteria reference sequence files.
Download all *genomic.fna.gz files to the directory by using command.
```
wget --recursive --continue ftp://ftp.ncbi.nlm.nih.gov/refseq/release/bacteria/*genomic.fna.gz
```

Unzip the files and concatenate all the files into a single file.
Use "bwa index" command to create index for the BWA algorithm.

3. Add paths to `human_g1k_v37.fasta` and `Bacteria_ref_genome.fna` to environment variables.
```
echo 'export REF_GENOME_HUMAN=$HOME/databases/ref_genomes/human_g1k_v37.fasta' >> $HOME/.bashrc
echo 'export REF_BACTERIA=$HOME/databases/bacteria_ref_sequence/Bacteria_ref_genome.fna' >> $HOME/.bashrc
source $HOME/.bashrc
```

### Install workflow 

Clone this repo and cd to repo
(Change URL accordingly if using HTTPS)

```
git clone git@github.com:avilab/quantify-virome.git
cd quantify-virome
```

### Example

#### Dry run

```
snakemake -n
```

#### Create workflow graph

```
snakemake -d .test --dag | dot -Tsvg > graph/dag.svg
```

#### Run workflow

This workflow is designed to run on hpc cluster, e.g. slurm. `cluster.json` configuration file may need some customisation, for example partition name. Memory nad maximum runtime limits are optimised for 20 splits. Number of splits can be specified in `config.yaml` file with n_files option (currently n_files is 2). Installation of software dependencies is taken care by conda and singularity, hence there is software installation overhead when you run this workflow for the first time in new environment. 

Example workflow submission script for slurm cluster, where values for job name, cluster partition name, time and memory constraints, and slurm log path (output) are taken from cluster.json: 
```
snakemake -j --use-conda --cluster-config cluster.json  \
             --cluster "sbatch -J {cluster.name} \
             -p {cluster.partition} \
             -t {cluster.time} \
             --mem {cluster.mem} \
             --output {cluster.output}"
```

You may want to use also following flags when running this workflow in cluster:
```
--max-jobs-per-second 1 --max-status-checks-per-second 10 --rerun-incomplete --keep-going
```

All other possible [snakemake execution](https://snakemake.readthedocs.io/en/stable/executable.html) options can be printed by calling `snakemake -h`.

### Exit/deactivate environment

Conda environment can be closed with the following command when work is finished:
```
source deactivate
```

### Workflow graph

For technical reasons, workflow is split into two parts, virome and taxonomy, that can be run separately, but taxonomy depends on the output of virome. Virome subworkflow (virome.snakefile) munges, masks, and blasts input sequences. Taxonomy subworkflow (Snakefile) merges blast results with taxonomy data and generates report.

![Virome workflow](graph/dag.svg)

Figure 1. **Workflow** graph with test sample split into two (default = 20) subfiles for parallel processing.

## References

<a id="1">[1]</a> H. Wu, E. Esteve, V. Tremaroli, M.T. Khan, R. Caesar, L. Mannerås-Holm, M. Ståhlman, L.M. Olsson, M. Serino, M. Planas-Fèlix, et al. Metformin alters the gut microbiome of individuals with treatment-naive type 2 diabetes, contributing to the therapeutic effects of the drug. Nat. Med., 23 (2017), pp. 850-858.

<a id="2">[2]</a> F.H. Karlsson, V. Tremaroli, I. Nookaew, G. Bergström, C.J. Behre, B. Fagerberg, J. Nielsen, F. Bäckhed Gut metagenome in European women with normal, impaired and diabetic glucose control. Nature, 498 (2013), pp. 99-103.

<a id="3">[3]</a> K. Forslund, F. Hildebrand, T. Nielsen, G. Falony, E. Le Chatelier, S. Sunagawa, E. Prifti, S. Vieira-Silva, V. Gudmundsdottir, H.K. Pedersen, et al., MetaHIT consortium Disentangling type 2 diabetes and metformin treatment signatures in the human gut microbiota. Nature, 528 (2015), pp. 262-266.

<a id="4">[4]</a> E. Le Chatelier, T. Nielsen, J. Qin, E. Prifti, F. Hildebrand, G. Falony, M. Almeida, M. Arumugam, J.M. Batto, S. Kennedy, et al., MetaHIT consortium. Richness of human gut microbiome correlates with metabolic markers. Nature, 500 (2013), pp. 541-546
