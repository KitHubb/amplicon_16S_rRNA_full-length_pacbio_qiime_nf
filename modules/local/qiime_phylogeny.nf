process QIIME_PHYLOGENY {

    tag "${params.run_label}:mafft_fasttree"
    label 'qiime_phylogeny'

    container { (workflow.containerEngine in ['singularity', 'apptainer'] && params.qiime_sif) ? params.qiime_sif : params.qiime_container }

    publishDir "${params.outdir}/phylogeny", mode: 'link', overwrite: true

    input:
    path repseq

    output:
    path 'aligned-rep-seqs.qza', emit: alignment
    path 'masked-aligned-rep-seqs.qza', emit: masked_alignment
    path 'unrooted-tree.qza', emit: unrooted_tree
    path 'rooted-tree.qza', emit: rooted_tree
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

    qiime phylogeny align-to-tree-mafft-fasttree \
      --i-sequences ${repseq} \
      --p-n-threads ${task.cpus} \
      --o-alignment aligned-rep-seqs.qza \
      --o-masked-alignment masked-aligned-rep-seqs.qza \
      --o-tree unrooted-tree.qza \
      --o-rooted-tree rooted-tree.qza

    for artifact in \
      aligned-rep-seqs.qza \
      masked-aligned-rep-seqs.qza \
      unrooted-tree.qza \
      rooted-tree.qza; do
        qiime tools validate --level max "\$artifact"
    done

    cat <<-END_VERSIONS > versions.yml
    "QIIME_PHYLOGENY":
      qiime2: \$(qiime --version 2>&1 | head -n 1)
    END_VERSIONS
    """
    stub:
    """
    touch aligned-rep-seqs.qza masked-aligned-rep-seqs.qza unrooted-tree.qza rooted-tree.qza
    echo "stub: true" > versions.yml
    """
}
