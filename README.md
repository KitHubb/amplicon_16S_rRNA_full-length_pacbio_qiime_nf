# amplicon_16S_qiime_nf

A lightweight Nextflow DSL2 workflow for PacBio full-length 16S CCS reads using QIIME 2 and Singularity/Apptainer.

## Workflow

```text
TAR or demultiplexed HiFi FASTQ
    -> samplesheet validation
    -> PacBio FASTQ preparation
    -> raw FastQC / MultiQC
    -> Cutadapt quality trimming + poly-G/poly-A cleanup
    -> clean FastQC / MultiQC
    -> QIIME 2 single-end manifest and import
    -> qiime dada2 denoise-ccs
    -> DADA2 table / representative sequence / statistics summaries
    -> SILVA classify-sklearn (optional)
    -> MAFFT + FastTree rooted phylogeny (default; optional)
```

The DADA2 command reproduces the validated analysis settings by explicitly providing the primer pair, 1000-bp minimum length, 1600-bp maximum length, and 16 threads. Other DADA2 parameters remain at the defaults of the installed QIIME 2 deployment.

## Tested environment

- Nextflow 26.04.2
- Singularity-CE 3.9.2
- FastQC 0.12.1
- MultiQC 1.27.1
- Cutadapt 5.2
- QIIME 2 Amplicon 2025.7

The repository does **not** include the Singularity image files or the SILVA classifier. Users must provide compatible local files and configure their paths as described below.

## Required container images

The workflow uses three container images:

| Parameter | Required software |
|---|---|
| `qc_sif` | FastQC and MultiQC |
| `cutadapt_sif` | Cutadapt |
| `qiime_sif` | QIIME 2 Amplicon with DADA2, feature-classifier, alignment, and phylogeny plugins |

The development server uses the following paths:

```text
/data/software/singularity/qc_fastqc_multiqc.sif
/data/software/singularity/read_cleanup_cutadapt-5.2.sif
/data/software/singularity/qiime2_amplicon_2025.7.sif
```

External users do **not** need to reproduce these directory paths. Point the workflow to the corresponding files on your own system using a local configuration file or command-line parameters.

## Run on another system

### 1. Create a local configuration file

Create `local.config` outside the repository or in your launch directory:

```groovy
params {
    qc_sif = '/absolute/path/to/qc_fastqc_multiqc.sif'
    cutadapt_sif = '/absolute/path/to/read_cleanup_cutadapt-5.2.sif'
    qiime_sif = '/absolute/path/to/qiime2_amplicon_2025.7.sif'

    taxonomy_classifier = '/absolute/path/to/silva-138-99-nb-classifier.qza'
}

singularity {
    enabled = true
    autoMounts = true
}
```

Use absolute paths whenever possible. The file names can differ from the examples as long as the images contain the required software.

Do not commit a machine-specific configuration file containing local paths:

```gitignore
local.config
```

### 2. Run directly from GitHub

```bash
nextflow -c local.config run KitHubb/amplicon_16S_qiime_nf \
  -profile singularity \
  --input /absolute/path/to/samplesheet.csv \
  --outdir /absolute/path/to/results \
  -resume
```

To run a fixed release, branch, or commit, add `-r`:

```bash
nextflow -c local.config run KitHubb/amplicon_16S_qiime_nf \
  -r main \
  -profile singularity \
  --input /absolute/path/to/samplesheet.csv \
  --outdir /absolute/path/to/results \
  -resume
```

### 3. Run from a cloned repository

```bash
git clone https://github.com/KitHubb/amplicon_16S_qiime_nf.git
cd amplicon_16S_qiime_nf

nextflow -c /absolute/path/to/local.config run main.nf \
  -profile singularity \
  --input /absolute/path/to/samplesheet.csv \
  --outdir /absolute/path/to/results \
  -resume
```

### Command-line path overrides

The same paths can be supplied without editing any config file:

```bash
nextflow run KitHubb/amplicon_16S_qiime_nf \
  -profile singularity \
  --input /absolute/path/to/samplesheet.csv \
  --outdir /absolute/path/to/results \
  --qc_sif /absolute/path/to/qc_fastqc_multiqc.sif \
  --cutadapt_sif /absolute/path/to/read_cleanup_cutadapt-5.2.sif \
  --qiime_sif /absolute/path/to/qiime2_amplicon_2025.7.sif \
  --taxonomy_classifier /absolute/path/to/silva-138-99-nb-classifier.qza \
  -resume
```

Command-line parameters have the highest priority and therefore override repository defaults, local config values, and parameter-file values.

### Important parameter precedence note

Nextflow resolves pipeline parameters in this order, from lowest to highest priority:

```text
pipeline defaults
    < config files
    < -params-file values
    < command-line --parameters
```

The bundled `params/pacbio_16s_default.yml` currently contains the development-server classifier path. Therefore, an external user who runs with that parameter file should also provide their classifier path on the command line:

```bash
nextflow -c local.config run KitHubb/amplicon_16S_qiime_nf \
  -profile singularity \
  -params-file params/pacbio_16s_default.yml \
  --input /absolute/path/to/samplesheet.csv \
  --outdir /absolute/path/to/results \
  --taxonomy_classifier /absolute/path/to/silva-138-99-nb-classifier.qza \
  -resume
```

Alternatively, copy the bundled YAML file, update the paths, and use the modified copy.

## Taxonomy classifier

Taxonomy assignment requires a QIIME 2 classifier artifact compatible with the installed QIIME 2 environment. The tested setup uses a SILVA 138 99% Naive Bayes classifier:

```text
silva-138-99-nb-classifier.qza
```

Disable taxonomy when a classifier is unavailable:

```bash
--taxonomy_enabled false
```

Phylogeny can be enabled or disabled independently:

```bash
--phylogeny_enabled true
--phylogeny_enabled false
```

## Input samplesheet

Required header:

```csv
sample_id,run_id,assay_id,library_round,sample_type,input_type,input_file
```

Supported input types:

- `fastq`: `.fastq`, `.fastq.gz`, `.fq`, or `.fq.gz`
- `tar`: one sample-level TAR archive containing one or more FASTQ files

Files containing `_trim_` are ignored when a TAR archive is prepared. Input paths should preferably be absolute, especially when launching the workflow directly from GitHub.

Example:

```csv
sample_id,run_id,assay_id,library_round,sample_type,input_type,input_file
Sample01,Run01,16S,1,Stool,tar,/data/FASTQ/Run01/Sample01_cell1.tar
Sample02,Run01,16S,1,Stool,fastq,/data/FASTQ/Run01/Sample02_HiFi.fastq.gz
```

## Create a samplesheet

```bash
bash bin/make_samplesheet.sh \
  /data/FASTQ/HN00280036 \
  assets/HN00280036_samplesheet.csv \
  HN00280036 \
  tar \
  Unknown \
  Study
```

Review and correct the generated metadata, especially `library_round` and `sample_type`, before analysis.

## Static checks

```bash
bash tests/test_python_and_shell.sh
nextflow config -profile singularity > resolved_nextflow.config.txt
```

Check the installed QIIME commands before the first run:

```bash
singularity exec \
  /absolute/path/to/qiime2_amplicon_2025.7.sif \
  qiime dada2 denoise-ccs --help

singularity exec \
  /absolute/path/to/qiime2_amplicon_2025.7.sif \
  qiime phylogeny align-to-tree-mafft-fasttree --help
```

## One-sample test run

Create a one-sample test samplesheet:

```bash
{
  head -n 1 assets/samplesheet.csv
  sed -n '2p' assets/samplesheet.csv
} > assets/one_sample.csv
```

Run the core workflow without taxonomy or phylogeny:

```bash
nextflow -c local.config run main.nf \
  -profile singularity \
  --input assets/one_sample.csv \
  --outdir results/one_sample \
  --taxonomy_enabled false \
  --phylogeny_enabled false \
  -resume \
  -ansi-log false
```

After the core workflow succeeds, enable downstream stages:

```bash
nextflow -c local.config run main.nf \
  -profile singularity \
  --input assets/one_sample.csv \
  --outdir results/one_sample \
  --taxonomy_enabled true \
  --phylogeny_enabled true \
  -resume \
  -ansi-log false
```

## Full run

```bash
mkdir -p logs

nohup nextflow -c local.config run main.nf \
  -profile singularity \
  --input /absolute/path/to/samplesheet.csv \
  --outdir /absolute/path/to/results \
  --taxonomy_enabled true \
  --phylogeny_enabled true \
  -resume \
  -ansi-log false \
  > logs/full_run.log 2>&1 &
```

Monitor the run:

```bash
tail -f logs/full_run.log
```

Optional Nextflow reports can be added with `-with-report`, `-with-trace`, `-with-timeline`, and `-with-dag`. Some minimal container images do not include the `ps` command required for task-metric collection. In that case, either install `procps`/`procps-ng` in the relevant image or run without those reporting options.

## Main outputs

```text
results/
├── input_validation/
├── input_preparation/
├── raw_qc/
│   ├── fastqc/
│   └── multiqc/
├── read_cleanup/
├── clean_qc/
│   ├── fastqc/
│   └── multiqc/
├── cleanup_qc/
│   └── cleanup_qc_summary.tsv
├── qiime_import/
│   ├── qiime_manifest_ccs.tsv
│   ├── samples_raw.qza
│   └── samples_raw.demux.summary.qzv
├── qiime_dada2/
│   ├── dada2-ccs_table.qza
│   ├── dada2-ccs_table.qzv
│   ├── dada2-ccs_rep.qza
│   ├── dada2-ccs_rep.qzv
│   ├── dada2-ccs_stats.qza
│   └── dada2-ccs_stats.qzv
├── taxonomy/
│   └── <taxonomy_reference_id>/
│       ├── taxonomy.qza
│       ├── taxonomy.qzv
│       ├── taxonomy.tsv
│       └── taxonomy_barplot.qzv
└── phylogeny/
    ├── aligned-rep-seqs.qza
    ├── masked-aligned-rep-seqs.qza
    ├── unrooted-tree.qza
    └── rooted-tree.qza
```

## Generic PacBio TAR preparation

`PREPARE_PACBIO_INPUT` runs once per samplesheet row and does not hard-code sample names. For `input_type=tar`, the task extracts that row's TAR file, excludes files containing `_trim_`, and normalizes the remaining `.fastq`, `.fastq.gz`, `.fq`, or `.fq.gz` files into:

```text
<sample_id>.raw.fastq.gz
```

The original input TAR or FASTQ files are not modified.

## Reproducibility recommendations

- Use a tagged repository release with `-r` rather than an unpinned development branch.
- Record the exact SIF files and classifier artifact used for each analysis.
- Keep `nextflow.config`, any local configuration, the samplesheet, and the resolved configuration with the analysis records.
- Use `-resume` only with the same input data and parameter set.
- Validate the final QIIME 2 artifacts before downstream statistical analysis.
