# Development plan

## Stage 1 — implemented

- samplesheet validation
- TAR/FASTQ preparation
- raw FastQC/MultiQC
- optional primer audit
- terminal poly-A/poly-G and complementary-head cleanup
- optional sequencing-adapter cleanup
- cleaned FastQC/MultiQC
- Cutadapt summary

## Stage 2

- build QIIME 2 CCS manifest
- import as `SampleData[SequencesWithQuality]`
- demux summary

## Stage 3

- `qiime dada2 denoise-ccs`
- min length 1000
- max length 1600
- DADA2 stats and base-transition outputs supported by QIIME 2 2025.7

## Stage 4

- SILVA classify-sklearn, externally overrideable classifier path
- confidence parameter exposed

## Stage 5

- MAFFT alignment, mask, FastTree, midpoint root
- standardized exports for R/phyloseq
