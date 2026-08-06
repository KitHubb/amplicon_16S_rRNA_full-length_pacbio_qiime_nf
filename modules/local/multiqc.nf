process MULTIQC_RAW {

    tag 'raw_fastqc'
    label 'qc'

    container "${params.qc_sif}"

    publishDir "${params.outdir}/raw_qc/multiqc", mode: 'copy', overwrite: true

    input:
    path fastqc_archives

    output:
    path 'multiqc_report.html', emit: report
    path 'multiqc_data', emit: data
    path 'versions.yml', emit: versions

    script:
    """
    multiqc \
      --force \
      --outdir . \
      ${fastqc_archives}

    cat <<-END_VERSIONS > versions.yml
    "MULTIQC_RAW":
      multiqc: \$(multiqc --version | sed 's/multiqc, version //')
    END_VERSIONS
    """
}

process MULTIQC_CLEAN {

    tag 'clean_fastqc'
    label 'qc'

    container "${params.qc_sif}"

    publishDir "${params.outdir}/clean_qc/multiqc", mode: 'copy', overwrite: true

    input:
    path fastqc_archives

    output:
    path 'multiqc_report.html', emit: report
    path 'multiqc_data', emit: data
    path 'versions.yml', emit: versions

    script:
    """
    multiqc \
      --force \
      --outdir . \
      ${fastqc_archives}

    cat <<-END_VERSIONS > versions.yml
    "MULTIQC_CLEAN":
      multiqc: \$(multiqc --version | sed 's/multiqc, version //')
    END_VERSIONS
    """
}
