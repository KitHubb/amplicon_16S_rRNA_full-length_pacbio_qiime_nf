include { PREPARE_PACBIO_INPUT } from '../../modules/local/prepare_pacbio_input'

workflow INPUT_PREPARATION {

    take:
    samplesheet

    main:
    input_ch = samplesheet
        .splitCsv(header: true)
        .map { row ->
            def meta = [
                id            : row.sample_id,
                run_id        : row.run_id,
                assay_id      : row.assay_id,
                library_round : row.library_round,
                sample_type   : row.sample_type,
                input_type    : row.input_type
            ]

            tuple(meta, file(row.input_file, checkIfExists: true))
        }

    PREPARE_PACBIO_INPUT(input_ch)

    emit:
    reads = PREPARE_PACBIO_INPUT.out.reads
    inventory = PREPARE_PACBIO_INPUT.out.inventory
}
