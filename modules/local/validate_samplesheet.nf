process VALIDATE_SAMPLESHEET {

    tag "${samplesheet.baseName}"
    label 'input_prep'

    publishDir "${params.outdir}/input_validation", mode: 'copy', overwrite: true

    input:
    path samplesheet

    output:
    path 'samplesheet.validated.csv', emit: validated_samplesheet
    path 'versions.yml', emit: versions

    script:
    """
    validate_samplesheet.py \
      ${samplesheet} \
      samplesheet.validated.csv

    cat <<-END_VERSIONS > versions.yml
    "VALIDATE_SAMPLESHEET":
      python: \$(python3 --version 2>&1 | awk '{print \$2}')
    END_VERSIONS
    """
}
