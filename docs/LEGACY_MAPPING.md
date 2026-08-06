# Mapping from the previously used shell scripts

## QC and cleanup

The prior `01_run_qc_XpoluG.sh` behavior is represented by
`READ_CLEANUP_SE`:

- `--quality-cutoff 30`
- `--minimum-length 100`
- `-a G{10}`
- added `-a A{10}` as requested

Raw FastQC/MultiQC is run before cleanup, and clean FastQC/MultiQC is run after
cleanup.

## QIIME import and DADA2 CCS

The prior `02_run_dada2.sh` is separated into four reusable steps:

1. `MAKE_QIIME_MANIFEST_CCS`
2. `QIIME_IMPORT_CCS`
3. `QIIME_DADA2_CCS`
4. `QIIME_FEATURE_SUMMARY`

The DADA2 command explicitly sets only:

- front primer: `AGRGTTYGATYMTGGCTCAG`
- adapter/reverse primer: `RGYTACCTTGTTACGACTT`
- minimum length: `1000`
- maximum length: `1600`
- threads: `16`

## Taxonomy

The prior `03_run_taxonomy.sh` is represented by `QIIME_TAXONOMY`, with:

- externally configurable classifier
- 16 jobs
- confidence `0.8`
- taxonomy table visualization
- taxa barplot
- exported `taxonomy.tsv`

## Phylogeny

`QIIME_PHYLOGENY` is a new default-enabled downstream stage using QIIME 2
`align-to-tree-mafft-fasttree`. It can be disabled independently.
