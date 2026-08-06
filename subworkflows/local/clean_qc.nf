include { FASTQC_CLEAN } from '../../modules/local/fastqc'
include { MULTIQC_CLEAN } from '../../modules/local/multiqc'

workflow CLEAN_QC {

    take:
    reads

    main:
    FASTQC_CLEAN(reads)

    fastqc_archives = FASTQC_CLEAN.out.reports
        .map { meta, zip_file, html_file -> zip_file }
        .collect()

    MULTIQC_CLEAN(fastqc_archives)

    emit:
    reports = FASTQC_CLEAN.out.reports
    multiqc_report = MULTIQC_CLEAN.out.report
}
