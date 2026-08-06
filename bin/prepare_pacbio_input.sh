#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 5 ]]; then
    echo "Usage: prepare_pacbio_input.sh <sample_id> <input_type> <input_file> <output_fastq.gz> <inventory.tsv>" >&2
    exit 1
fi

SAMPLE_ID="$1"
INPUT_TYPE="$2"
INPUT_FILE="$3"
OUTPUT_FASTQ="$4"
INVENTORY_TSV="$5"

if [[ ! -f "$INPUT_FILE" ]]; then
    echo "[ERROR] Input file not found: $INPUT_FILE" >&2
    exit 1
fi

TMP_EXTRACT_DIR="$(mktemp -d "${TMPDIR:-/tmp}/pacbio_input.XXXXXX")"
trap 'rm -rf "$TMP_EXTRACT_DIR"' EXIT

FASTQ_FILES=()

case "$INPUT_TYPE" in
    tar)
        tar -xf "$INPUT_FILE" -C "$TMP_EXTRACT_DIR"

        mapfile -t FASTQ_FILES < <(
            find "$TMP_EXTRACT_DIR" -type f \
              \( -name '*.fastq' -o -name '*.fastq.gz' -o -name '*.fq' -o -name '*.fq.gz' \) \
              ! -name '*_trim_*' \
              -print | LC_ALL=C sort
        )
        ;;

    fastq)
        FASTQ_FILES=("$INPUT_FILE")
        ;;

    *)
        echo "[ERROR] Unsupported input_type '$INPUT_TYPE'. Use tar or fastq." >&2
        exit 1
        ;;
esac

if [[ ${#FASTQ_FILES[@]} -eq 0 ]]; then
    echo "[ERROR] No non-trim FASTQ file found for sample: $SAMPLE_ID" >&2
    exit 1
fi

{
    for fastq_file in "${FASTQ_FILES[@]}"; do
        case "$fastq_file" in
            *.gz) gzip -dc -- "$fastq_file" ;;
            *)    cat -- "$fastq_file" ;;
        esac
    done
} | gzip -c > "$OUTPUT_FASTQ"

gzip -t "$OUTPUT_FASTQ"

printf 'sample_id\tinput_type\tsource_file\tfastq_files_found\tprepared_fastq\n' \
  > "$INVENTORY_TSV"

printf '%s\t%s\t%s\t%s\t%s\n' \
  "$SAMPLE_ID" \
  "$INPUT_TYPE" \
  "$INPUT_FILE" \
  "${#FASTQ_FILES[@]}" \
  "$OUTPUT_FASTQ" \
  >> "$INVENTORY_TSV"

printf '[DONE] Sample: %s\n' "$SAMPLE_ID"
printf '[DONE] FASTQ files combined: %s\n' "${#FASTQ_FILES[@]}"
printf '[DONE] Prepared FASTQ: %s\n' "$OUTPUT_FASTQ"
