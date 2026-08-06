# QIIME artifact publishing fix

- QIIME outputs are published with hard links (`mode: link`) because `work/` and `results/` are on the same filesystem.
- Each QIIME process validates its QZA artifacts before the task can succeed.
- CLI boolean strings such as `--taxonomy_enabled false` and `--phylogeny_enabled false` are normalized with `toBoolean()`.
- Do not use `nextflow clean` until published artifacts have been independently validated. Hard-linked results remain available after removal of the work-directory link.
