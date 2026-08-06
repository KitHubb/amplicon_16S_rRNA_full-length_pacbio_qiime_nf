#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

python3 -m py_compile \
  bin/validate_samplesheet.py \
  bin/summarize_cutadapt_json.py

bash -n bin/make_samplesheet.sh
bash -n bin/prepare_pacbio_input.sh

required_files=(
  main.nf
  nextflow.config
  params/pacbio_16s_default.yml
  modules/local/prepare_pacbio_input.nf
  modules/local/qiime_import_ccs.nf
  modules/local/qiime_dada2_ccs.nf
  modules/local/qiime_taxonomy.nf
  modules/local/qiime_phylogeny.nf
)

for file in "${required_files[@]}"; do
    [[ -f "$file" ]] || {
        echo "[ERROR] Missing required file: $file" >&2
        exit 1
    }
done

grep -q 'prepare_pacbio_input.sh' modules/local/prepare_pacbio_input.nf
grep -q 'qiime dada2 denoise-ccs' modules/local/qiime_dada2_ccs.nf
grep -q -- '--p-front' modules/local/qiime_dada2_ccs.nf
grep -q -- '--p-min-len' modules/local/qiime_dada2_ccs.nf
grep -q 'classify-sklearn' modules/local/qiime_taxonomy.nf
grep -q 'align-to-tree-mafft-fasttree' modules/local/qiime_phylogeny.nf
grep -q "mode: 'link'" modules/local/qiime_import_ccs.nf
grep -q "mode: 'link'" modules/local/qiime_dada2_ccs.nf
grep -q 'qiime tools validate --level max samples_raw.qza' modules/local/qiime_import_ccs.nf
grep -q 'qiime tools validate --level max' modules/local/qiime_dada2_ccs.nf
grep -q 'taxonomy_enabled = params.taxonomy_enabled.toString().trim().toBoolean()' main.nf
grep -q 'phylogeny_enabled = params.phylogeny_enabled.toString().trim().toBoolean()' main.nf
grep -q -- "-a 'polyG=" modules/local/read_cleanup.nf
grep -q -- "-a 'polyA=" modules/local/read_cleanup.nf

# Test generic TAR input preparation with one retained FASTQ and one excluded *_trim_* FASTQ.
TEST_DIR="$(mktemp -d)"
trap 'rm -rf "$TEST_DIR"' EXIT
mkdir -p "$TEST_DIR/tar_content"

printf '@read_raw\nACGT\n+\nIIII\n' | gzip -c \
  > "$TEST_DIR/tar_content/AnySample_HiFi.fastq.gz"

printf '@read_trim\nTTTT\n+\nIIII\n' | gzip -c \
  > "$TEST_DIR/tar_content/AnySample_trim_HiFi.fastq.gz"

tar -cf "$TEST_DIR/AnySample_cell1.tar" \
  -C "$TEST_DIR/tar_content" \
  AnySample_HiFi.fastq.gz \
  AnySample_trim_HiFi.fastq.gz

bin/prepare_pacbio_input.sh \
  AnySample \
  tar \
  "$TEST_DIR/AnySample_cell1.tar" \
  "$TEST_DIR/AnySample.raw.fastq.gz" \
  "$TEST_DIR/AnySample.input_inventory.tsv" \
  >/dev/null

gzip -t "$TEST_DIR/AnySample.raw.fastq.gz"
zcat "$TEST_DIR/AnySample.raw.fastq.gz" | grep -q '^@read_raw$'

if zcat "$TEST_DIR/AnySample.raw.fastq.gz" | grep -q '^@read_trim$'; then
    echo '[ERROR] *_trim_* FASTQ was not excluded' >&2
    exit 1
fi

awk -F '\t' 'NR == 2 { if ($1 != "AnySample" || $4 != "1") exit 1 }' \
  "$TEST_DIR/AnySample.input_inventory.tsv"

echo '[PASS] Python, shell, static pipeline, and generic TAR input tests completed.'
