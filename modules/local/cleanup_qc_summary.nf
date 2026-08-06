process CLEANUP_QC_SUMMARY {

    tag "${params.run_label}:cleanup_summary"
    label 'read_cleanup'

    container "${params.cutadapt_sif}"

    publishDir "${params.outdir}/cleanup_qc", mode: 'copy', overwrite: true

    input:
    path cutadapt_json_files

    output:
    path 'cleanup_qc_summary.tsv', emit: summary
    path 'versions.yml', emit: versions

    script:
    """
    summarize_cutadapt_json.py \
      --output cleanup_qc_summary.tsv \
      ${cutadapt_json_files}

    cat <<-END_VERSIONS > versions.yml
    "CLEANUP_QC_SUMMARY":
      python: \$(python3 --version 2>&1 | awk '{print \$2}')
    END_VERSIONS
    """
}
