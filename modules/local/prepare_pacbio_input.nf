process PREPARE_PACBIO_INPUT {

    tag "${meta.id}:${meta.input_type}"
    label 'input_prep'

    container { (workflow.containerEngine in ['singularity', 'apptainer'] && params.cutadapt_sif) ? params.cutadapt_sif : params.cutadapt_container }

    publishDir "${params.outdir}/input_preparation",
        mode: 'copy',
        overwrite: true,
        pattern: '*.input_inventory.tsv'

    input:
    tuple val(meta), path(input_file)

    output:
    tuple val(meta), path("${meta.id}.raw.fastq.gz"), emit: reads
    tuple val(meta), path("${meta.id}.input_inventory.tsv"), emit: inventory
    path 'versions.yml', emit: versions

    script:
    def sample_id = meta.id as String
    def input_type = meta.input_type as String

    """
    prepare_pacbio_input.sh \
      '${sample_id}' \
      '${input_type}' \
      '${input_file}' \
      '${sample_id}.raw.fastq.gz' \
      '${sample_id}.input_inventory.tsv'

    cat <<-END_VERSIONS > versions.yml
    "PREPARE_PACBIO_INPUT":
      bash: \$(bash --version | head -n 1)
      gzip: \$(gzip --version | head -n 1 | awk '{print \$2}')
      tar: \$(tar --version | head -n 1)
    END_VERSIONS
    """
}
