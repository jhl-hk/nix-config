# Upstream

| | |
|---|---|
| Source | https://github.com/Leonxlnx/taste-skill — `skills/taste-skill/` |
| Commit | `f6b76575f949707b4e3c37cd86cb44b0b98643e8` |
| License | MIT |

## Local changes

Diverged; merge upstream by hand. Untouched: `assets/`, `library/`, `scripts/` (code).

- Directory renamed `taste-skill` → `design-taste-frontend` to match `name`.
- `node` → `bun` in every command (each script behaves the same under bun); requirements: bun (or Node 22+), Chrome/Edge/Chromium, ffmpeg optional. The frontmatter Stop hook runs `gate.mjs` with bun when present, else node.
- `SKILL.md`: version/marketing preamble removed; description = triggers + `Not for` boundaries (impeccable for existing product UI, animation skills, break-ui, mobile-native, jianyuelab-ui); body rebuilt Overview / When to Use / Core Pattern / Quick Reference (the run, steps 0–7) / Implementation / Common Mistakes; headings no longer numbered (cross-references now by section name); usual existing-project stack named (Astro, React/Vue islands, Tailwind, `@jianyuelab/tokens`); manual gate run required on every harness except Claude Code (Stop hook).
- `gate.md`: per-harness hook installs → one table plus an "Other harnesses (e.g. omp)" row; `npx skills`/`install.sh` mention dropped.
- Copy references: `copy.md` is the single home of the copy-lint spec, file map, sub-line lengths, form words and footer legal row; the model's default voice lives only in `copy-voice.md` §2; others link.
- Sections, cards, moments, scenes, backgrounds: "in testing" stories and retired-row history removed (retired moment ids kept as one rule); card depth and fragment rules live in `cards.md`; moment rules beside scenes link to `moments.md`.
- Effects: `effects-usage.md` is the single home of the gate, one-effect budget, four-context limit and cost numbers; dead `fx-logos`/`fx-band` mentions removed.
- `motion.md`: opens with pointers to animate, choreograph, micro-interaction, accessible-animation, animation-performance; kit tokens/hooks/values kept; "Not yet placed, so not used" list removed.
- `photos.md`: curation-history note removed; licensing, credit, stand-in and report rules unchanged.
- `icons.md`, `diagrams.md`: deduplicated (diagrams links to icons for sources and colour).
