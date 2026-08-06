#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 4 || $# -gt 6 ]]; then
    echo "Usage: make_samplesheet.sh <input_dir> <output.csv> <run_id> <input_type> [library_round] [sample_type]" >&2
    exit 1
fi

INPUT_DIR="$(cd "$1" && pwd)"
OUTPUT_CSV="$2"
RUN_ID="$3"
INPUT_TYPE="$4"
LIBRARY_ROUND="${5:-Unknown}"
SAMPLE_TYPE="${6:-Study}"

if [[ "$INPUT_TYPE" != "fastq" && "$INPUT_TYPE" != "tar" ]]; then
    echo "[ERROR] input_type must be fastq or tar" >&2
    exit 1
fi

mkdir -p "$(dirname "$OUTPUT_CSV")"
echo "sample_id,run_id,assay_id,library_round,sample_type,input_type,input_file" > "$OUTPUT_CSV"

if [[ "$INPUT_TYPE" == "tar" ]]; then
    mapfile -t FILES < <(find "$INPUT_DIR" -maxdepth 1 -type f -name '*.tar' | sort)
else
    mapfile -t FILES < <(
        find "$INPUT_DIR" -maxdepth 1 -type f \
          \( -name '*.fastq' -o -name '*.fastq.gz' -o -name '*.fq' -o -name '*.fq.gz' \) \
          ! -name '*_trim_*' | sort
    )
fi

if [[ ${#FILES[@]} -eq 0 ]]; then
    echo "[ERROR] No matching input files found in $INPUT_DIR" >&2
    exit 1
fi

for input_file in "${FILES[@]}"; do
    base="$(basename "$input_file")"
    sample_id="$base"
    sample_id="${sample_id%.tar}"
    sample_id="${sample_id%.fastq.gz}"
    sample_id="${sample_id%.fastq}"
    sample_id="${sample_id%.fq.gz}"
    sample_id="${sample_id%.fq}"
    sample_id="${sample_id%_cell1}"
    sample_id="${sample_id%_HiFi}"
    sample_id="${sample_id%_HiFi.filt}"

    printf '%s,%s,16S_full,%s,%s,%s,%s\n' \
      "$sample_id" "$RUN_ID" "$LIBRARY_ROUND" "$SAMPLE_TYPE" "$INPUT_TYPE" "$input_file" \
      >> "$OUTPUT_CSV"
done

echo "[DONE] Created: $OUTPUT_CSV"
echo "[DONE] Samples: ${#FILES[@]}"
