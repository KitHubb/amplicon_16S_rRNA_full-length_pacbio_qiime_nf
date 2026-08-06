include { MAKE_QIIME_MANIFEST_CCS } from '../../modules/local/make_qiime_manifest_ccs'

workflow BUILD_QIIME_MANIFEST_CCS {

    take:
    cleaned_reads

    main:
    manifest_records = cleaned_reads
        .map { meta, reads ->
            "${meta.id}\t${reads.getName()}"
        }
        .collectFile(
            name: 'qiime_manifest_ccs.records.tsv',
            newLine: true,
            sort: true
        )

    fastq_files = cleaned_reads
        .map { meta, reads -> reads }
        .collect()

    MAKE_QIIME_MANIFEST_CCS(manifest_records)

    emit:
    manifest_template = MAKE_QIIME_MANIFEST_CCS.out.manifest_template
    fastq_files = fastq_files
}
