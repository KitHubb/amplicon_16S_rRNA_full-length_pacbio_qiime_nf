include { FASTQC_RAW } from '../../modules/local/fastqc'
include { MULTIQC_RAW } from '../../modules/local/multiqc'

workflow RAW_QC {

    take:
    reads

    main:
    FASTQC_RAW(reads)

    fastqc_archives = FASTQC_RAW.out.reports
        .map { meta, zip_file, html_file -> zip_file }
        .collect()

    MULTIQC_RAW(fastqc_archives)

    emit:
    reports = FASTQC_RAW.out.reports
    multiqc_report = MULTIQC_RAW.out.report
}
