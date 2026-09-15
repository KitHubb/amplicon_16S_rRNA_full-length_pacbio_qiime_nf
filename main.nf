nextflow.enable.dsl = 2

params.input = null
params.outdir = 'results'

include { VALIDATE_SAMPLESHEET } from './modules/local/validate_samplesheet'
include { INPUT_PREPARATION } from './subworkflows/local/input_preparation'
include { RAW_QC } from './subworkflows/local/raw_qc'
include { READ_CLEANUP } from './subworkflows/local/read_cleanup'
include { CLEAN_QC } from './subworkflows/local/clean_qc'
include { CLEANUP_QC } from './subworkflows/local/cleanup_qc_summary'
include { BUILD_QIIME_MANIFEST_CCS } from './subworkflows/local/build_qiime_manifest_ccs'
include { QIIME_IMPORT_CCS } from './modules/local/qiime_import_ccs'
include { QIIME_DADA2_CCS } from './modules/local/qiime_dada2_ccs'
include { QIIME_FEATURE_SUMMARY } from './modules/local/qiime_feature_summary'
include { QIIME_TAXONOMY } from './modules/local/qiime_taxonomy'
include { QIIME_PHYLOGENY } from './modules/local/qiime_phylogeny'

workflow {

    taxonomy_enabled = params.taxonomy_enabled.toString().trim().toBoolean()
    phylogeny_enabled = params.phylogeny_enabled.toString().trim().toBoolean()

    if (!params.input) {
        error 'Please provide --input <samplesheet.csv>'
    }

    if (!params.dada2_front || !params.dada2_adapter) {
        error 'dada2_front and dada2_adapter must be provided'
    }

    if (params.dada2_min_len < 1 || params.dada2_max_len < params.dada2_min_len) {
        error 'Invalid DADA2 length range: dada2_min_len must be >=1 and <= dada2_max_len'
    }

    if (!params.stop_after_qc.toString().toBoolean() && taxonomy_enabled && !params.taxonomy_classifier) {
        error 'taxonomy_enabled=true requires taxonomy_classifier'
    }

    samplesheet_ch = Channel.fromPath(
        params.input,
        checkIfExists: true
    )

    VALIDATE_SAMPLESHEET(samplesheet_ch)

    INPUT_PREPARATION(
        VALIDATE_SAMPLESHEET.out.validated_samplesheet
    )

    // Raw read quality assessment.
    RAW_QC(
        INPUT_PREPARATION.out.reads
    )

    // Quality trimming plus poly-G/poly-A cleanup.
    READ_CLEANUP(
        INPUT_PREPARATION.out.reads
    )

    // Cleaned read quality assessment.
    CLEAN_QC(
        READ_CLEANUP.out.cleaned_reads
    )

    CLEANUP_QC(
        READ_CLEANUP.out.cleanup_json
    )

    if (!params.stop_after_qc.toString().toBoolean()) {
        BUILD_QIIME_MANIFEST_CCS(
            READ_CLEANUP.out.cleaned_reads
        )

        QIIME_IMPORT_CCS(
            BUILD_QIIME_MANIFEST_CCS.out.manifest_template,
            BUILD_QIIME_MANIFEST_CCS.out.fastq_files
        )

        QIIME_DADA2_CCS(
            QIIME_IMPORT_CCS.out.demux
        )

        QIIME_FEATURE_SUMMARY(
            QIIME_DADA2_CCS.out.table,
            QIIME_DADA2_CCS.out.repseq,
            QIIME_DADA2_CCS.out.stats
        )

        if (taxonomy_enabled) {
            classifier_ch = Channel.fromPath(
                params.taxonomy_classifier,
                checkIfExists: true
            )

            QIIME_TAXONOMY(
                QIIME_DADA2_CCS.out.table,
                QIIME_DADA2_CCS.out.repseq,
                classifier_ch
            )
        }

        if (phylogeny_enabled) {
            QIIME_PHYLOGENY(
                QIIME_DADA2_CCS.out.repseq
            )
        }
    }
}
