# Upstream

| | |
|---|---|
| Source | https://github.com/anthropics/skills — `skills/xlsx/` |
| Commit | `2c5958ecac7cee2b583967a2c4981d0f4a75c579` |
| License | Apache-2.0 |

## Local changes

- Description: the Word-document exclusion became `Not for a Word document deliverable; use docx.`; the other exclusions (HTML report, Python script, database pipeline, Google Sheets API) stay.
- Dropped the upstream-sandbox claim that `openpyxl`, `pandas` and `markitdown` are preinstalled: import directly and `pip install` only on failure (intro note and Dependencies).
