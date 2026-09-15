#!/usr/bin/env python3
"""Verify actual cleanup behavior or explicitly labelled full-graph stub outputs."""
import argparse
import csv
import gzip
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('outdir', type=Path)
parser.add_argument('--stub', action='store_true')
args = parser.parse_args()
root = args.outdir
for name in ['input_validation/samplesheet.validated.csv',
             'input_preparation/Synthetic.input_inventory.tsv',
             'raw_qc/multiqc/multiqc_report.html',
             'clean_qc/multiqc/multiqc_report.html',
             'cleanup_qc/cleanup_qc_summary.tsv']:
    assert (root / name).is_file(), name
if args.stub:
    for name in ['qiime_import/samples_raw.qza', 'qiime_dada2/dada2-ccs_table.qza',
                 'qiime_dada2/dada2-ccs_rep.qzv', 'phylogeny/rooted-tree.qza',
                 'taxonomy/silva_138_99/taxonomy.tsv']:
        assert (root / name).is_file(), name
else:
    with gzip.open(root / 'read_cleanup/Synthetic.clean.fastq.gz', 'rt') as f:
        lines = f.read().splitlines()
    raw = (Path(__file__).parent / 'data/reads.fastq').read_text().splitlines()
    assert len(lines) == len(raw) == 80
    for i in range(0, len(lines), 4):
        assert lines[i + 1] == raw[i + 1][:-20]
        assert len(lines[i + 3]) == 1200
    with (root / 'cleanup_qc/cleanup_qc_summary.tsv').open() as f:
        rows = list(csv.DictReader(f, delimiter='\t'))
    assert len(rows) == 1
    assert rows[0]['input_reads'] == rows[0]['output_reads'] == '20'
    assert rows[0]['polyG_matches'] == '20'
    assert not (root / 'qiime_dada2').exists()
print('PASS: ' + ('stub graph outputs' if args.stub else 'QC outputs and poly-G removal'))
