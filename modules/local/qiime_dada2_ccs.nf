process QIIME_DADA2_CCS {

    tag "${params.run_label}:dada2_ccs"
    label 'qiime_dada2'

    container "${params.qiime_sif}"

    publishDir "${params.outdir}/qiime_dada2", mode: 'link', overwrite: true

    input:
    path demux

    output:
    path 'dada2-ccs_table.qza', emit: table
    path 'dada2-ccs_rep.qza', emit: repseq
    path 'dada2-ccs_stats.qza', emit: stats
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

    qiime dada2 denoise-ccs \
      --i-demultiplexed-seqs ${demux} \
      --p-front '${params.dada2_front}' \
      --p-adapter '${params.dada2_adapter}' \
      --p-min-len ${params.dada2_min_len} \
      --p-max-len ${params.dada2_max_len} \
      --p-n-threads ${task.cpus} \
      --o-table dada2-ccs_table.qza \
      --o-representative-sequences dada2-ccs_rep.qza \
      --o-denoising-stats dada2-ccs_stats.qza

    for artifact in \
      dada2-ccs_table.qza \
      dada2-ccs_rep.qza \
      dada2-ccs_stats.qza; do
        qiime tools validate --level max "\$artifact"
    done

    cat <<-END_VERSIONS > versions.yml
    "QIIME_DADA2_CCS":
      qiime2: \$(qiime --version 2>&1 | head -n 1)
    END_VERSIONS
    """
}
