process FASTQC_RAW {

    tag "${meta.id}:raw"
    label 'qc'

    container "${params.qc_sif}"

    publishDir "${params.outdir}/raw_qc/fastqc", mode: 'copy', overwrite: true

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path('*_fastqc.zip'), path('*_fastqc.html'), emit: reports
    path 'versions.yml', emit: versions

    script:
    """
    fastqc \
      --threads ${task.cpus} \
      --outdir . \
      ${reads}

    cat <<-END_VERSIONS > versions.yml
    "FASTQC_RAW":
      fastqc: \$(fastqc --version | sed 's/FastQC v//')
    END_VERSIONS
    """
}

process FASTQC_CLEAN {

    tag "${meta.id}:clean"
    label 'qc'

    container "${params.qc_sif}"

    publishDir "${params.outdir}/clean_qc/fastqc", mode: 'copy', overwrite: true

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path('*_fastqc.zip'), path('*_fastqc.html'), emit: reports
    path 'versions.yml', emit: versions

    script:
    """
    fastqc \
      --threads ${task.cpus} \
      --outdir . \
      ${reads}

    cat <<-END_VERSIONS > versions.yml
    "FASTQC_CLEAN":
      fastqc: \$(fastqc --version | sed 's/FastQC v//')
    END_VERSIONS
    """
}
