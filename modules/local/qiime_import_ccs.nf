process QIIME_IMPORT_CCS {

    tag "${params.run_label}:ccs_import"
    label 'qiime_import'

    container "${params.qiime_sif}"

    publishDir "${params.outdir}/qiime_import", mode: 'link', overwrite: true

    input:
    path manifest_template
    path fastq_files

    output:
    path 'qiime_manifest_ccs.tsv', emit: manifest
    path 'samples_raw.qza', emit: demux
    path 'samples_raw.demux.summary.qzv', emit: summary
    path 'versions.yml', emit: versions

    script:
    """
    export TMPDIR="\$PWD/qiime_tmp"
    export TMP="\$TMPDIR"
    export TEMP="\$TMPDIR"
    export NUMBA_CACHE_DIR="\$PWD/numba_cache"
    export MPLCONFIGDIR="\$PWD/matplotlib_cache"
    export XDG_CACHE_HOME="\$PWD/xdg_cache"

    mkdir -p \
      "\$TMPDIR" \
      "\$NUMBA_CACHE_DIR" \
      "\$MPLCONFIGDIR" \
      "\$XDG_CACHE_HOME"

    declare -A FASTQ_LOOKUP

    for fastq_file in ${fastq_files}; do
        FASTQ_LOOKUP["\$(basename "\$fastq_file")"]="\$(realpath "\$fastq_file")"
    done

    printf 'sample-id\tabsolute-filepath\n' > qiime_manifest_ccs.tsv

    tail -n +2 ${manifest_template} | while IFS=\$'\t' read -r sample_id file_name; do
        if [[ -z "\${FASTQ_LOOKUP[\$file_name]:-}" ]]; then
            echo "[ERROR] FASTQ listed in manifest template was not staged: \$file_name" >&2
            exit 1
        fi

        printf '%s\t%s\n' \
          "\$sample_id" \
          "\${FASTQ_LOOKUP[\$file_name]}" \
          >> qiime_manifest_ccs.tsv
    done

    qiime tools import \
      --type 'SampleData[SequencesWithQuality]' \
      --input-path qiime_manifest_ccs.tsv \
      --input-format SingleEndFastqManifestPhred33V2 \
      --output-path samples_raw.qza

    qiime demux summarize \
      --i-data samples_raw.qza \
      --o-visualization samples_raw.demux.summary.qzv

    qiime tools validate --level max samples_raw.qza

    cat <<-END_VERSIONS > versions.yml
    "QIIME_IMPORT_CCS":
      qiime2: \$(qiime --version 2>&1 | head -n 1)
    END_VERSIONS
    """
}
