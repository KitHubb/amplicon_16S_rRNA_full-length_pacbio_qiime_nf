process QIIME_TAXONOMY {

    tag "${params.run_label}:${params.taxonomy_reference_id}"
    label 'qiime_taxonomy'

    container { (workflow.containerEngine in ['singularity', 'apptainer'] && params.qiime_sif) ? params.qiime_sif : params.qiime_container }

    publishDir "${params.outdir}/taxonomy/${params.taxonomy_reference_id}",
        mode: 'link',
        overwrite: true

    input:
    path table
    path repseq
    path classifier

    output:
    path 'taxonomy.qza', emit: taxonomy
    path 'taxonomy.qzv', emit: taxonomy_summary
    path 'taxonomy_barplot.qzv', emit: barplot
    path 'taxonomy.tsv', emit: taxonomy_tsv
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

    qiime feature-classifier classify-sklearn \
      --i-classifier ${classifier} \
      --i-reads ${repseq} \
      --p-confidence ${params.taxonomy_confidence} \
      --p-reads-per-batch ${params.taxonomy_reads_per_batch} \
      --p-n-jobs ${task.cpus} \
      --o-classification taxonomy.qza

    qiime tools validate --level max taxonomy.qza

    qiime metadata tabulate \
      --m-input-file taxonomy.qza \
      --o-visualization taxonomy.qzv

    qiime taxa barplot \
      --i-table ${table} \
      --i-taxonomy taxonomy.qza \
      --o-visualization taxonomy_barplot.qzv

    qiime tools export \
      --input-path taxonomy.qza \
      --output-path taxonomy_export

    cp taxonomy_export/taxonomy.tsv taxonomy.tsv

    cat <<-END_VERSIONS > versions.yml
    "QIIME_TAXONOMY":
      qiime2: \$(qiime --version 2>&1 | head -n 1)
    END_VERSIONS
    """
    stub:
    """
    touch taxonomy.qza taxonomy.qzv taxonomy_barplot.qzv taxonomy.tsv
    echo "stub: true" > versions.yml
    """
}
