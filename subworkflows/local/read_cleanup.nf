include { READ_CLEANUP_SE } from '../../modules/local/read_cleanup'

workflow READ_CLEANUP {

    take:
    reads

    main:
    READ_CLEANUP_SE(reads)

    emit:
    cleaned_reads = READ_CLEANUP_SE.out.cleaned_reads
    cleanup_json = READ_CLEANUP_SE.out.json
    cleanup_log = READ_CLEANUP_SE.out.log
}
