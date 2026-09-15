#!/usr/bin/env python3
import csv
import os
import re
import sys

REQUIRED = [
    "sample_id",
    "run_id",
    "assay_id",
    "library_round",
    "sample_type",
    "input_type",
    "input_file",
]

ALLOWED_INPUT_TYPES = {"fastq", "tar"}
FASTQ_SUFFIXES = (".fastq", ".fastq.gz", ".fq", ".fq.gz")
SAMPLE_ID_PATTERN = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]*$")


def fail(message: str) -> None:
    sys.exit(f"[ERROR] {message}")


def main() -> None:
    if len(sys.argv) != 3:
        fail("Usage: validate_samplesheet.py <input.csv> <output.csv>")

    input_csv, output_csv = sys.argv[1], sys.argv[2]
    seen = set()
    valid_rows = []

    with open(input_csv, newline="", encoding="utf-8-sig") as handle:
        reader = csv.DictReader(handle)

        if reader.fieldnames != REQUIRED:
            found = ",".join(reader.fieldnames or [])
            expected = ",".join(REQUIRED)
            fail(f"Header must be exactly:\n{expected}\nFound:\n{found}")

        for line_no, row in enumerate(reader, start=2):
            row = {key: (value or "").strip() for key, value in row.items()}
            sample_id = row["sample_id"]
            input_type = row["input_type"].lower()
            input_file = row["input_file"]
            if not os.path.isabs(input_file):
                input_file = os.path.join(os.path.dirname(os.path.realpath(input_csv)), input_file)
            input_file = os.path.abspath(input_file)

            if not sample_id:
                fail(f"Row {line_no}: empty sample_id")
            if not SAMPLE_ID_PATTERN.fullmatch(sample_id):
                fail(
                    f"Row {line_no}: invalid sample_id '{sample_id}'. "
                    "Use letters, numbers, dots, underscores, or hyphens only."
                )
            if sample_id in seen:
                fail(f"Row {line_no}: duplicated sample_id: {sample_id}")
            seen.add(sample_id)

            if not row["run_id"]:
                fail(f"Row {line_no}: empty run_id")
            if row["assay_id"] != "16S_full":
                fail(f"Row {line_no}: assay_id must be 16S_full")
            if input_type not in ALLOWED_INPUT_TYPES:
                fail(f"Row {line_no}: input_type must be fastq or tar")
            if not os.path.isfile(input_file):
                fail(f"Row {line_no}: input file not found: {input_file}")

            if input_type == "fastq" and not input_file.lower().endswith(FASTQ_SUFFIXES):
                fail(f"Row {line_no}: unsupported FASTQ suffix: {input_file}")
            if input_type == "tar" and not input_file.lower().endswith(".tar"):
                fail(f"Row {line_no}: tar input must end with .tar: {input_file}")

            row["input_type"] = input_type
            row["input_file"] = input_file
            valid_rows.append(row)

    if not valid_rows:
        fail("No data rows were found")

    with open(output_csv, "w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=REQUIRED)
        writer.writeheader()
        writer.writerows(valid_rows)

    print(f"[DONE] Samples: {len(valid_rows)}")
    print(f"[DONE] Validated samplesheet: {output_csv}")


if __name__ == "__main__":
    main()
