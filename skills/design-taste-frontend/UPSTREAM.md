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
- `SKILL.md` Quick Reference (the run) is a numbered list of commands with one line each; the prose moved to the references it cites: stack → `system.md` Stack; build steps → `system.md` Build; plan lines → `sections.md` section 1; palette/pairing, `--has`, tech-only grounds and short-page rules → `sections.md` section 2; radius by kind → `system.md` Radius and buttons; script running rules, widths, fix rounds → `gate.md` Running the checks; the Next.js `out` root → `gate.md` Arm it; the `.md` draft lint → `copy.md` copy-lint. The per-kind deal lists in step 4 replaced by a pointer to `sections.md` section 3 (they were a copy). When to Use no longer repeats the description's `Not for` list. The Never line "Finishing without a gate run outside Claude Code" (a repeat of step 6) → "Hiding anything from the checker" with a waiver pointer. The checklist's Motion line points to house rule 5 instead of restating it.
- `motion.md`: Tokens opens with the scope line (kit tokens apply on tasteskill pages; motion outside the kit uses the animate skill's values); `--u-spring` noted as a cubic-bezier, not a spring; the linked card's 180ms noted as a literal in `motion.css` with no token; the pause-disc placement moved here from `cards.md`. Kit values unchanged.
- Single homes enforced: hover numbers (2px lift, 1.03 zoom, 600ms, nav 150ms and 6px drop) now only in `motion.md` and SKILL.md house rule 5 (pointers in `cards.md`, `sections.md`, `sections-library.md`, `photos.md`, `effects-creative.md`, `system.md`); pause disc only in `motion.md`; WebGL cap and render limits only in `effects-usage.md` (`perf.md` keeps the 21–24ms pixel-ratio drop; `cards.md`, `moments.md` cite `effects-usage.md` for the cap); `diagrams.md` cycle points to `--m-cycle` and drops the two-loops repeat; `moments.md` curve and develop time point to `motion.md`; `effects-creative.md` drops its first 5 s pause line; `effects-usage.md` "What each kind gets" drops the diagram and CSS-ground rows (in SKILL.md's Implementation table). `moments.md` link "The rule" → "Three places move, nothing else".
- `copy.md`, `copy-moves.md`: restatements of the Five rules cut ("`copy.md` wins" kept).
