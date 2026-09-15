#!/usr/bin/env python3
"""Input path and release guard regressions, requiring only Python 3."""
import csv
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
HEADER = 'sample_id,run_id,assay_id,library_round,sample_type,input_type,input_file\n'
ROW = 'Test,Run,16S_full,1,Synthetic,fastq,reads.fastq\n'


class ValidationTests(unittest.TestCase):
    def test_staged_relative_path_and_duplicate_rejection(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / 'reads.fastq').write_text('@r\nACGT\n+\nIIII\n')
            source = root / 'samples.csv'
            source.write_text(HEADER + ROW)
            stage = root / 'stage'
            stage.mkdir()
            (stage / 'samples.csv').symlink_to(source)
            command = ['python3', str(ROOT / 'bin/validate_samplesheet.py'),
                       str(stage / 'samples.csv'), str(root / 'out.csv')]
            result = subprocess.run(command, cwd=str(stage), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            self.assertEqual(result.returncode, 0, result.stderr)
            with (root / 'out.csv').open() as f:
                self.assertEqual(list(csv.DictReader(f))[0]['input_file'], str(root / 'reads.fastq'))
            source.write_text(HEADER + ROW + ROW)
            result = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn(b'duplicated sample_id', result.stderr)

    def test_release_tag_guard(self):
        command = ['python3', str(ROOT / 'tests/release_notes.py')]
        result = subprocess.run(command + ['v0.0.9'], cwd=str(ROOT), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(b'Automatic version-pinned BioContainers', result.stdout)
        result = subprocess.run(command + ['v0.0.8'], cwd=str(ROOT), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn(b'does not match', result.stderr)


if __name__ == '__main__':
    unittest.main()
