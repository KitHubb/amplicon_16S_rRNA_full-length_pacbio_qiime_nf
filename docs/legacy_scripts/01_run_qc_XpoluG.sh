#!/bin/bash

# ===========================================
# 16S Full-length HiFi FASTQ.gz QC 파이프라인
# Tools:
#   - cutadapt (in qiime2-amplicon-2024.2)
#   - fastqc + multiqc (in multiqc)
#   - seqkit (optional, globally installed)
#   + PolyG 제거 옵션 추가
# ===========================================

# ----------- Conda 경로 지정 -----------
CONDA="/home/ksy/anaconda3/bin/conda"

# ----------- 입력 인자 확인 -----------
INPUT_DIR="$1"
OUTPUT_DIR="$2"
QC_SCORE="$3"

if [ -z "$INPUT_DIR" ] || [ -z "$OUTPUT_DIR" ] || [ -z "$QC_SCORE" ]; then
    echo "Usage: bash 01_run_qc.sh <input_dir> <output_dir> <qc_score>"
    exit 1
fi

# ----------- 경로 및 폴더 생성 -----------
CUTADAPT_DIR="${OUTPUT_DIR}/cutadapt"
FASTQC_DIR="${OUTPUT_DIR}/fastqc"
MULTIQC_DIR="${OUTPUT_DIR}/multiqc"
LOG_DIR="${OUTPUT_DIR}/logs"

mkdir -p "$CUTADAPT_DIR" "$FASTQC_DIR" "$MULTIQC_DIR" "$LOG_DIR"

# ----------- Step 1: Cutadapt -----------
echo "[Step 1] Cutadapt filtering..."
for i in "${INPUT_DIR}"/*_HiFi.fastq.gz; do
    SAMPLE=$(basename "$i" _HiFi.fastq.gz)
    echo "[Cutadapt] Processing $SAMPLE" | tee -a "${LOG_DIR}/cutadapt.log"

    $CONDA run -n qiime2-amplicon-2024.2 cutadapt \
        --minimum-length 100 \
         -a "G{10}" \
        -q "$QC_SCORE" \
        -o "${CUTADAPT_DIR}/${SAMPLE}_HiFi.filt.fastq.gz" \
        "$i" \
        >> "${LOG_DIR}/cutadapt.log" 2>&1
done

# ----------- Step 2: FastQC -----------
echo "[Step 2] Running FastQC..."
for fq in "${CUTADAPT_DIR}"/*.fastq.gz; do
    echo "[FastQC] $fq" | tee -a "${LOG_DIR}/fastqc.log"
    $CONDA run -n multiqc fastqc "$fq" -o "$FASTQC_DIR" >> "${LOG_DIR}/fastqc.log" 2>&1
done

# ----------- Step 3: MultiQC -----------
echo "[Step 3] Running MultiQC..."
$CONDA run -n multiqc multiqc "$FASTQC_DIR" -o "$MULTIQC_DIR" >> "${LOG_DIR}/multiqc.log" 2>&1

# ----------- Step 4: Seqkit (optional) -----------
echo "[Step 4] Running seqkit stats..."
if command -v seqkit &> /dev/null; then
    seqkit stats -T -a "${CUTADAPT_DIR}"/*.fastq.gz > "${LOG_DIR}/summary_seqkit.tsv"
else
    echo "[Warning] seqkit not found. Skipping summary stats."
fi

# ----------- 완료 메시지 -----------
echo "QC Pipeline Finished."
echo "Cutadapt output : ${CUTADAPT_DIR}"
echo "FastQC output   : ${FASTQC_DIR}"
echo "MultiQC report  : ${MULTIQC_DIR}"
echo "Logs saved to   : ${LOG_DIR}"
