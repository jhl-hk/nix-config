# Upstream

| | |
|---|---|
| Source | https://github.com/anthropics/skills — `skills/docx/` |
| Commit | `2c5958ecac7cee2b583967a2c4981d0f4a75c579` |
| License | Apache-2.0 |

## Local changes

- Description: the closing exclusion now names the neighbouring skills (`Not for PDFs, spreadsheets or slide decks; use pdf / xlsx / pptx.`); Google Docs and unrelated coding stay excluded.
- Dropped the upstream-sandbox claim that `docx` is preinstalled: require it directly and `bun add docx` only if the require fails (gotchas intro and Dependencies).
- "then Read the images" (harness tool name) → "then view the images".
