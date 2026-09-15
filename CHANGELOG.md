# Changelog

## [0.0.9] - 2026-09-15

### Added

- Automatic version-pinned BioContainers for FastQC, MultiQC and Cutadapt, plus the official QIIME 2 Amplicon 2025.7 image.
- Docker and Apptainer profiles alongside Singularity, preserving optional local SIF overrides.
- Synthetic QC test, full workflow stub test, output assertions and CI diagnostics.
- GitHub release creation after successful CI on version tags, with manifest/tag validation.

### Changed

- Removed machine-specific container and classifier defaults; taxonomy requires an explicit compatible classifier.
- Resolve relative FASTQ/TAR paths relative to the source samplesheet.
- Add `--stop_after_qc` for QC-only runs.
