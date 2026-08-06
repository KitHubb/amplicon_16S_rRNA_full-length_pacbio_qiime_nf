#!/usr/bin/env python3
import argparse
import csv
import json
import os


def as_int(value):
    return int(value or 0)


def pct(numerator, denominator):
    return round((100.0 * numerator / denominator), 4) if denominator else 0.0


def adapter_match_counts(report):
    counts = {"polyG_matches": 0, "polyA_matches": 0}

    for adapter in report.get("adapters_read1", []) or []:
        name = adapter.get("name", "")
        key = f"{name}_matches"
        if key in counts:
            counts[key] += as_int(adapter.get("total_matches"))

    return counts


def main():
    parser = argparse.ArgumentParser(
        description="Summarize Cutadapt JSON reports for PacBio 16S cleanup."
    )
    parser.add_argument("--output", required=True)
    parser.add_argument("json_files", nargs="+")
    args = parser.parse_args()

    fields = [
        "sample_id",
        "cutadapt_version",
        "input_reads",
        "output_reads",
        "retained_percent",
        "reads_with_any_adapter",
        "too_short",
        "too_long",
        "too_many_n",
        "quality_trimmed_bp",
        "output_bp",
        "polyG_matches",
        "polyA_matches",
    ]

    rows = []
    for json_file in sorted(args.json_files):
        with open(json_file, encoding="utf-8") as handle:
            report = json.load(handle)

        counts = report.get("read_counts", {}) or {}
        filtered = counts.get("filtered", {}) or {}
        basepairs = report.get("basepair_counts", {}) or {}

        input_reads = as_int(counts.get("input"))
        output_reads = as_int(counts.get("output"))

        row = {
            "sample_id": os.path.basename(json_file).replace(".cleanup.json", ""),
            "cutadapt_version": report.get("cutadapt_version", "unknown"),
            "input_reads": input_reads,
            "output_reads": output_reads,
            "retained_percent": pct(output_reads, input_reads),
            "reads_with_any_adapter": as_int(counts.get("read1_with_adapter")),
            "too_short": as_int(filtered.get("too_short")),
            "too_long": as_int(filtered.get("too_long")),
            "too_many_n": as_int(filtered.get("too_many_n")),
            "quality_trimmed_bp": as_int(basepairs.get("quality_trimmed")),
            "output_bp": as_int(basepairs.get("output")),
        }
        row.update(adapter_match_counts(report))
        rows.append(row)

    with open(args.output, "w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=fields,
            delimiter="\t",
            lineterminator="\n",
        )
        writer.writeheader()
        writer.writerows(rows)

    print(f"[DONE] Samples summarized: {len(rows)}")
    print(f"[DONE] Output: {args.output}")


if __name__ == "__main__":
    main()
