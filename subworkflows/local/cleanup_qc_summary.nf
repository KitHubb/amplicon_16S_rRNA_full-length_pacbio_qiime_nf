include { CLEANUP_QC_SUMMARY } from '../../modules/local/cleanup_qc_summary'

workflow CLEANUP_QC {

    take:
    cutadapt_json

    main:
    json_files = cutadapt_json
        .map { meta, json_file -> json_file }
        .collect()

    CLEANUP_QC_SUMMARY(json_files)

    emit:
    summary = CLEANUP_QC_SUMMARY.out.summary
}
