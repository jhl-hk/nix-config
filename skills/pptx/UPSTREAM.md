# Upstream

| | |
|---|---|
| Source | https://github.com/anthropics/skills — `skills/pptx/` |
| Commit | `2c5958ecac7cee2b583967a2c4981d0f4a75c579` |
| License | Apache-2.0 |

## Local changes

- Description: added `Not for Word, spreadsheet or PDF deliverables; use docx / xlsx / pdf.`
- Dropped the upstream-sandbox wording: `soffice.py` row now says bare `soffice` hangs in sandboxed environments (was "in this sandbox"); `pptxgenjs` and the icon packages are no longer called preinstalled, install with `bun add` only if a require fails (gotchas intro, Icons bullet, Dependencies).
- "Pass the absolute paths … directly to the view tool" (harness tool name) → "View the images at the absolute paths printed above."
- Rules stated twice kept once, in the Avoid list: text-box padding (gotcha merged into the Avoid bullet), text-only slides ("Every slide needs a visual element" merged into the Avoid bullet), colour bars as a motif (Before Starting aside removed), default blue (Color Palettes lead-in removed).
