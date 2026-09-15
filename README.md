# amplicon_16S_rRNA_full-length_pacbio_qiime_nf

A lightweight Nextflow DSL2 workflow for PacBio full-length 16S CCS reads using QIIME 2 with Docker, Singularity or Apptainer.

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

## Containers and quick start (v0.0.9)

Nextflow downloads these public images automatically for the selected runtime:

| Parameter | Default image |
|---|---|
| `fastqc_container` | `quay.io/biocontainers/fastqc:0.12.1--hdfd78af_0` |
| `multiqc_container` | `quay.io/biocontainers/multiqc:1.27.1--pyhdfd78af_0` |
| `cutadapt_container` | `quay.io/biocontainers/cutadapt:5.2--py310h1fe012e_0` |
| `qiime_container` | `quay.io/qiime2/amplicon:2025.7` |

QC tools use [BioContainers](https://bioconda.github.io/recipes/multiqc/README.html).
QIIME uses its [official distribution](https://github.com/qiime2/distributions) to include the compatible DADA2, classifier and phylogeny plugins.
Tags were checked against the Quay registry. Override image parameters to use your own compatible images or digest-pinned references.

Requirements: Nextflow >=26.04.2, Java 17+, Python 3 on the host, and one container runtime. Samplesheet validation runs on the host because it checks input paths before Nextflow stages those files. Analysis tools run in containers. Public images target Linux x86-64; initial downloads require network access and available disk space.

```bash
nextflow run . -profile docker \
  --input /absolute/path/to/samplesheet.csv \
  --taxonomy_classifier /absolute/path/to/compatible-classifier.qza \
  --outdir results/analysis -resume
```

Replace `docker` with `singularity` or `apptainer` for automatic image conversion/caching. Select one runtime profile per run. With Docker, output files use your host UID/GID.

For existing local images, use `-profile singularity` or `-profile apptainer` and override `--qc_sif`, `--cutadapt_sif`, and `--qiime_sif`. These default to null and are ignored by Docker. The combined `qc_sif` must contain both FastQC and MultiQC; the Cutadapt image also needs Bash, gzip and tar for input preparation. Custom `_container` parameters are also supported. Keep local paths in an untracked `local.config`.

The classifier is not bundled. Supply `--taxonomy_classifier` or disable taxonomy with `--taxonomy_enabled false`. The default parameter YAML no longer overrides classifier paths.

## Tests and CI

```bash
# Python/shell regressions
bash tests/test_python_and_shell.sh

# Full graph including optional taxonomy, without containers or analysis tools
nextflow run . -profile test_stub -stub-run \
  --taxonomy_enabled true --taxonomy_classifier tests/data/classifier.stub \
  --outdir results/stub
python3 tests/check_outputs.py results/stub --stub

# Actual FastQC, MultiQC and Cutadapt on bundled synthetic reads
nextflow run . -profile test,docker
python3 tests/check_outputs.py results/test
```

`test` stops after QC, checks all 20 reads are retained, and verifies removal of the synthetic poly-G tails. It needs no classifier or external sequencing data. `test_full` enables the core QIIME workflow and phylogeny; use `-profile test_full,docker -stub-run` to check container wiring, or provide real CCS data with `--input` for actual analysis. `test_stub` selects the same graph with all container runtimes disabled; always pass `-stub-run`. Stub `.qza`/`.qzv` files are placeholders, not valid analysis artifacts. Synthetic reads are not a DADA2 accuracy or error-learning test.

CI runs script checks, profile resolution, the full graph stub test including taxonomy, and actual Docker QC. A pushed `v0.0.9` tag publishes a GitHub Release only after these tests pass and the tag matches the manifest. Notes come from the corresponding section of [CHANGELOG.md](CHANGELOG.md). Creating/pushing a tag is a separate maintainer action. Full biological DADA2/classifier validation requires real data and is not part of the small CI test.

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

Files containing `_trim_` are ignored when a TAR archive is prepared. Relative input paths resolve against the original samplesheet directory. Absolute paths are also supported.

Example:

```csv
sample_id,run_id,assay_id,library_round,sample_type,input_type,input_file
Sample01,Run01,16S_full,1,Stool,tar,/data/FASTQ/Run01/Sample01_cell1.tar
Sample02,Run01,16S_full,1,Stool,fastq,/data/FASTQ/Run01/Sample02_HiFi.fastq.gz
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
