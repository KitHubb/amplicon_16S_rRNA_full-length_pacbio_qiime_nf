# amplicon_16S_qiime_nf

A lightweight Nextflow DSL2 workflow for PacBio full-length 16S CCS reads using
QIIME 2 2025.7 and Singularity.

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

The DADA2 command reproduces the previously used analysis settings by explicitly
providing only the primer pair, 1000-bp minimum length, 1600-bp maximum length,
and 16 threads. Other DADA2 parameters remain at the QIIME 2 deployment defaults.

## Server requirements

- Nextflow 26.04.2
- Singularity-CE 3.9.2
- `/data/software/singularity/qiime2_amplicon_2025.7.sif`
- `/data/software/singularity/qc_fastqc_multiqc.sif`
- `/data/software/singularity/read_cleanup_cutadapt-5.2.sif`

Default classifier path:

```text
/data/Reference/QIIME2-2025.7/Bacteria/SILVA/silva-138-99-nb-classifier.qza
```

Until that classifier is installed, run with `--taxonomy_enabled false`.

## Input samplesheet

Required header:

```csv
sample_id,run_id,assay_id,library_round,sample_type,input_type,input_file
```

Supported input types:

- `fastq`: `.fastq`, `.fastq.gz`, `.fq`, `.fq.gz`
- `tar`: one sample-level TAR archive containing FASTQ files

Files containing `_trim_` are ignored when a TAR archive is prepared.

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

Review and correct `library_round` before analysis.

## Static checks

```bash
bash tests/test_python_and_shell.sh
nextflow config -profile singularity > resolved_nextflow.config.txt
```

Check the installed QIIME commands before the first run:

```bash
singularity exec \
  /data/software/singularity/qiime2_amplicon_2025.7.sif \
  qiime dada2 denoise-ccs --help

singularity exec \
  /data/software/singularity/qiime2_amplicon_2025.7.sif \
  qiime phylogeny align-to-tree-mafft-fasttree --help
```

## One-sample development run

```bash
{
  head -n 1 assets/HN00280036_samplesheet.csv
  sed -n '2p' assets/HN00280036_samplesheet.csv
} > assets/HN00280036_one_sample.csv

mkdir -p results/HN00280036_one_sample

nextflow run main.nf \
  -profile singularity \
  -params-file params/pacbio_16s_default.yml \
  --input assets/HN00280036_one_sample.csv \
  --outdir results/HN00280036_one_sample \
  --taxonomy_enabled false \
  -resume \
  -with-report results/HN00280036_one_sample/execution_report.html \
  -with-trace results/HN00280036_one_sample/execution_trace.txt \
  -with-timeline results/HN00280036_one_sample/execution_timeline.html \
  -with-dag results/HN00280036_one_sample/pipeline_dag.html
```

## Full run

```bash
mkdir -p results/HN00280036

nohup nextflow run main.nf \
  -profile singularity \
  -params-file params/pacbio_16s_default.yml \
  --input assets/HN00280036_samplesheet.csv \
  --outdir results/HN00280036 \
  -resume \
  -with-report results/HN00280036/execution_report.html \
  -with-trace results/HN00280036/execution_trace.txt \
  -with-timeline results/HN00280036/execution_timeline.html \
  -with-dag results/HN00280036/pipeline_dag.html \
  > HN00280036.nextflow.log 2>&1 &
```

Disable optional downstream stages independently:

```bash
--taxonomy_enabled false
--phylogeny_enabled false
```

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
├── taxonomy/silva_138_99/
└── phylogeny/
```

## Generic PacBio TAR preparation

`PREPARE_PACBIO_INPUT` runs once per samplesheet row. It does not hard-code sample names. For `input_type=tar`, the task extracts that row's TAR file, excludes `*_trim_*`, and normalizes the remaining `.fastq`, `.fastq.gz`, `.fq`, or `.fq.gz` files into `<sample_id>.raw.fastq.gz`.
