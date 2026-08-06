#!/bin/bash

# ===========================================
# QIIME2 Import + DADA2 CCS 파이프라인
# ===========================================

# ----------- Conda 경로 지정 -----------
CONDA="/home/ksy/anaconda3/bin/conda"

# ----------- 입력 인자 확인 -----------
INPUT_DIR="$1"   # 필터링된 fastq.gz가 있는 디렉토리
OUTPUT_DIR="$2"  # 분석 결과 저장 경로

if [ -z "$INPUT_DIR" ] || [ -z "$OUTPUT_DIR" ]; then
    echo "Usage: bash 02_run_qiime_dada2.sh <input_fastq_dir> <output_dir>"
    exit 1
fi

# ----------- 경로 및 폴더 생성 -----------
mkdir -p "$OUTPUT_DIR"
DADA2_DIR="${OUTPUT_DIR}/Dada2"
LOG_DIR="${OUTPUT_DIR}/logs"
mkdir -p "$DADA2_DIR" "$LOG_DIR"

# ----------- manifest 파일은 INPUT_DIR 내에 생성 -----------
MANIFEST="${INPUT_DIR}/sample_list.txt"

# ----------- Step 1: Manifest 파일 생성 -----------
echo "[Step 1] Creating manifest file..." | tee -a "${LOG_DIR}/import.log"

MANIFEST="${INPUT_DIR}/sample_list.txt"
echo -e "sample-id\tabsolute-filepath" > "$MANIFEST"

find "$INPUT_DIR" -name "*.fastq.gz" | while read fq; do
    id=$(basename "$fq" | sed 's/.fastq.gz$//')
    abs_path=$(realpath "$fq")          # 절대경로 변환
    echo -e "${id}\t${abs_path}"
done >> "$MANIFEST"

# 디버깅 출력
echo "생성된 manifest 예시 (상위 5줄):" | tee -a "${LOG_DIR}/import.log"
head -n 5 "$MANIFEST" | tee -a "${LOG_DIR}/import.log"


# ----------- Step 2: QIIME2 Import -----------
echo "[Step 2] Importing FASTQ into QIIME2..." | tee -a "${LOG_DIR}/import.log"
$CONDA run -n qiime2-amplicon-2024.2 qiime tools import \
  --type 'SampleData[SequencesWithQuality]' \
  --input-path "$MANIFEST" \
  --output-path "${OUTPUT_DIR}/samples_raw.qza" \
  --input-format SingleEndFastqManifestPhred33V2 \
  >> "${LOG_DIR}/import.log" 2>&1

# ----------- Step 3: Demux summary -----------
echo "[Step 3] Summarizing demultiplexed data..." | tee -a "${LOG_DIR}/import.log"
$CONDA run -n qiime2-amplicon-2024.2 qiime demux summarize \
  --i-data "${OUTPUT_DIR}/samples_raw.qza" \
  --o-visualization "${OUTPUT_DIR}/samples_raw.demux.summary.qzv" \
  >> "${LOG_DIR}/import.log" 2>&1

# ----------- Step 4: DADA2 CCS 분석 -----------
echo "[Step 4] Running DADA2 CCS..." | tee -a "${LOG_DIR}/dada2.log"
$CONDA run -n qiime2-amplicon-2024.2 qiime dada2 denoise-ccs \
  --i-demultiplexed-seqs "${OUTPUT_DIR}/samples_raw.qza" \
  --p-front AGRGTTYGATYMTGGCTCAG \
  --p-adapter RGYTACCTTGTTACGACTT \
  --p-min-len 1000 \
  --p-max-len 1600 \
  --o-table "${DADA2_DIR}/dada2-ccs_table.qza" \
  --o-representative-sequences "${DADA2_DIR}/dada2-ccs_rep.qza" \
  --o-denoising-stats "${DADA2_DIR}/dada2-ccs_stats.qza" \
  --p-n-threads 16 \
  >> "${LOG_DIR}/dada2.log" 2>&1

# ----------- Step 5: 시각화 생성 -----------
echo "[Step 5] Creating summaries..." | tee -a "${LOG_DIR}/dada2.log"

$CONDA run -n qiime2-amplicon-2024.2 qiime metadata tabulate \
  --m-input-file "${DADA2_DIR}/dada2-ccs_stats.qza" \
  --o-visualization "${DADA2_DIR}/dada2-ccs_stats.qzv" \
  >> "${LOG_DIR}/dada2.log" 2>&1

$CONDA run -n qiime2-amplicon-2024.2 qiime feature-table summarize \
  --i-table "${DADA2_DIR}/dada2-ccs_table.qza" \
  --o-visualization "${DADA2_DIR}/dada2-ccs_table.qzv" \
  >> "${LOG_DIR}/dada2.log" 2>&1

$CONDA run -n qiime2-amplicon-2024.2 qiime feature-table tabulate-seqs \
  --i-data "${DADA2_DIR}/dada2-ccs_rep.qza" \
  --o-visualization "${DADA2_DIR}/dada2-ccs_rep.qzv" \
  >> "${LOG_DIR}/dada2.log" 2>&1

# ----------- 완료 메시지 -----------
echo "QIIME2 DADA2 CCS 파이프라인 완료."
echo "결과 위치:"
echo "  Manifest:           ${MANIFEST}"
echo "  Raw import:         ${OUTPUT_DIR}/samples_raw.qza"
echo "  Demux summary:      ${OUTPUT_DIR}/samples_raw.demux.summary.qzv"
echo "  Feature table:      ${DADA2_DIR}/dada2-ccs_table.qza / .qzv"
echo "  Rep seqs:           ${DADA2_DIR}/dada2-ccs_rep.qza / .qzv"
echo "  Denoising stats:    ${DADA2_DIR}/dada2-ccs_stats.qza / .qzv"
echo "  Logs:               ${LOG_DIR}/"
