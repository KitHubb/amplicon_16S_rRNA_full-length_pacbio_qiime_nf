process MAKE_QIIME_MANIFEST_CCS {

    tag "${params.run_label}:ccs_manifest"
    label 'qiime_import'

    container { (workflow.containerEngine in ['singularity', 'apptainer'] && params.cutadapt_sif) ? params.cutadapt_sif : params.cutadapt_container }

    publishDir "${params.outdir}/qiime_import", mode: 'copy', overwrite: true,
        pattern: 'qiime_manifest_ccs.template.tsv'

    input:
    path manifest_records

    output:
    path 'qiime_manifest_ccs.template.tsv', emit: manifest_template
    path 'versions.yml', emit: versions

    script:
    """
    printf 'sample-id\tabsolute-filepath\n' > qiime_manifest_ccs.template.tsv
    cat ${manifest_records} >> qiime_manifest_ccs.template.tsv

    cat <<-END_VERSIONS > versions.yml
    "MAKE_QIIME_MANIFEST_CCS":
      bash: \$(bash --version | head -n 1)
    END_VERSIONS
    """
}
