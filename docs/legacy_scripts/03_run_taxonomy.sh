#!/bin/bash

# ===========================================
# QIIME2 Taxonomy Classification 파이프라인
# ===========================================

# ----------- Conda 경로 지정 -----------
CONDA="/home/ksy/anaconda3/bin/conda"

# ----------- 입력 인자 확인 -----------
CLASSIFIER="$1"         # 분류기 (예: silva-138-99-515-806-nb-classifier.qza)
CLASSIFIER_NAME="$2"    # 분류기 이름 (예: silva138, gg99 등)
INPUT_DIR="$3"          # DADA2 결과(qza 파일들)가 있는 디렉토리
OUTPUT_DIR="$4"         # taxonomy 결과 저장 디렉토리

if [ -z "$CLASSIFIER" ] || [ -z "$CLASSIFIER_NAME" ] || [ -z "$INPUT_DIR" ] || [ -z "$OUTPUT_DIR" ]; then
    echo "Usage: bash 03_run_taxonomy.sh <classifier> <classifier_name> <dada2_output_dir> <output_dir>"
    exit 1
fi

# ----------- 경로 및 폴더 생성 -----------
mkdir -p "$OUTPUT_DIR"
LOG_DIR="${OUTPUT_DIR}/logs"
mkdir -p "$LOG_DIR"

# ----------- Step 1: Taxonomy 분류 -----------
echo "[Step 1] Classifying sequences..." | tee -a "${LOG_DIR}/taxonomy.log"
$CONDA run -n qiime2-amplicon-2024.2 qiime feature-classifier classify-sklearn \
  --i-classifier "$CLASSIFIER" \
  --i-reads "${INPUT_DIR}/dada2-ccs_rep.qza" \
  --o-classification "${OUTPUT_DIR}/dada2-taxonomy_${CLASSIFIER_NAME}.qza" \
  --p-n-jobs 16 \
  >> "${LOG_DIR}/taxonomy.log" 2>&1

# ----------- Step 2: Barplot 생성 -----------
echo "[Step 2] Creating taxonomy barplot..." | tee -a "${LOG_DIR}/taxonomy.log"
$CONDA run -n qiime2-amplicon-2024.2 qiime taxa barplot \
  --i-table "${INPUT_DIR}/dada2-ccs_table.qza" \
  --i-taxonomy "${OUTPUT_DIR}/dada2-taxonomy_${CLASSIFIER_NAME}.qza" \
  --o-visualization "${OUTPUT_DIR}/dada2-taxonomy_${CLASSIFIER_NAME}_plot.qzv" \
  >> "${LOG_DIR}/taxonomy.log" 2>&1

echo "Taxonomy classification 완료."
echo "결과 위치:"
echo "  Taxonomy qza:   ${OUTPUT_DIR}/dada2-taxonomy_${CLASSIFIER_NAME}.qza"
echo "  Barplot qzv:    ${OUTPUT_DIR}/dada2-taxonomy_${CLASSIFIER_NAME}_plot.qzv"
echo "  Logs:           ${LOG_DIR}/taxonomy.log"
