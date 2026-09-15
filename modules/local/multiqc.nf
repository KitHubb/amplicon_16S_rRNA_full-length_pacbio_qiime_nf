process MULTIQC_RAW {

    tag 'raw_fastqc'
    label 'qc'

    container { (workflow.containerEngine in ['singularity', 'apptainer'] && params.qc_sif) ? params.qc_sif : params.multiqc_container }

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
    stub:
    """
    touch multiqc_report.html
    mkdir -p multiqc_data
    echo "stub: true" > versions.yml
    """
}

process MULTIQC_CLEAN {

    tag 'clean_fastqc'
    label 'qc'

    container { (workflow.containerEngine in ['singularity', 'apptainer'] && params.qc_sif) ? params.qc_sif : params.multiqc_container }

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
    stub:
    """
    touch multiqc_report.html
    mkdir -p multiqc_data
    echo "stub: true" > versions.yml
    """
}
