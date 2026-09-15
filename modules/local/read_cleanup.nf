process READ_CLEANUP_SE {

    tag "${meta.id}:cleanup"
    label 'read_cleanup'

    container { (workflow.containerEngine in ['singularity', 'apptainer'] && params.cutadapt_sif) ? params.cutadapt_sif : params.cutadapt_container }

    publishDir "${params.outdir}/read_cleanup", mode: 'copy', overwrite: true

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("${meta.id}.clean.fastq.gz"), emit: cleaned_reads
    tuple val(meta), path("${meta.id}.cleanup.json"), emit: json
    tuple val(meta), path("${meta.id}.cleanup.log"), emit: log
    path 'versions.yml', emit: versions

    script:
    def polyG = "G{${params.cleanup_poly_g_min_run}}"
    def polyA = "A{${params.cleanup_poly_a_min_run}}"

    """
    cutadapt \
      --cores ${task.cpus} \
      --minimum-length ${params.cleanup_min_length} \
      --quality-cutoff ${params.cleanup_quality_cutoff} \
      -a 'polyG=${polyG}' \
      -a 'polyA=${polyA}' \
      --json "${meta.id}.cleanup.json" \
      -o "${meta.id}.clean.fastq.gz" \
      ${reads} \
      > "${meta.id}.cleanup.log"

    cat <<-END_VERSIONS > versions.yml
    "READ_CLEANUP_SE":
      cutadapt: \$(cutadapt --version)
    END_VERSIONS
    """
    stub:
    """
    cp ${reads} ${meta.id}.clean.fastq.gz
    echo '{}' > ${meta.id}.cleanup.json
    touch ${meta.id}.cleanup.log
    echo "stub: true" > versions.yml
    """
}
