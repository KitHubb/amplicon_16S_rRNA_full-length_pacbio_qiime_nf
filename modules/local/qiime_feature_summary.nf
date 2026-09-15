process QIIME_FEATURE_SUMMARY {

    tag "${params.run_label}:feature_summary"
    label 'qiime_summary'

    container { (workflow.containerEngine in ['singularity', 'apptainer'] && params.qiime_sif) ? params.qiime_sif : params.qiime_container }

    publishDir "${params.outdir}/qiime_dada2", mode: 'link', overwrite: true

    input:
    path table
    path repseq
    path stats

    output:
    path 'dada2-ccs_table.qzv', emit: table_summary
    path 'dada2-ccs_rep.qzv', emit: repseq_summary
    path 'dada2-ccs_stats.qzv', emit: stats_summary
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

    qiime metadata tabulate \
      --m-input-file ${stats} \
      --o-visualization dada2-ccs_stats.qzv

    qiime feature-table summarize \
      --i-table ${table} \
      --o-visualization dada2-ccs_table.qzv

    qiime feature-table tabulate-seqs \
      --i-data ${repseq} \
      --o-visualization dada2-ccs_rep.qzv

    cat <<-END_VERSIONS > versions.yml
    "QIIME_FEATURE_SUMMARY":
      qiime2: \$(qiime --version 2>&1 | head -n 1)
    END_VERSIONS
    """
    stub:
    """
    touch dada2-ccs_table.qzv dada2-ccs_rep.qzv dada2-ccs_stats.qzv
    echo "stub: true" > versions.yml
    """
}
