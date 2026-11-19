# Upstream provenance

Vendored, not tracked as a flake input.

| | |
|---|---|
| Source | https://github.com/pbakaus/impeccable — `plugin/skills/impeccable/` |
| Commit | `d34c87e1a00989ae8dbdd7f6b30b70f23319e860` |
| Version | 4.8.0 |
| License | Apache-2.0 (© Paul Bakaus) |

## Why vendored

The repo's HEAD tree is 86 MiB across 4422 files. The skill is 2.2 MiB.

## Notes

- `scripts/impeccable` downloads its engine binary into `~/.impeccable/bin/<version>/` on first run, verified against `scripts/engine-checksums.txt`.
- Hooks are per project: `hooks on` writes `.claude/settings.local.json`, `.codex/hooks.json`, etc. omp has no hook; it acts on `MANUAL_DETECTOR_REQUIRED`.
- The engine binary still knows a `craft` command; `pin craft` would point at the deleted `reference/craft.md`.

## Local changes

Heavily diverged. Do not rsync over it: merge upstream changes by hand, file by file. Untouched: `scripts/impeccable`, `scripts/impeccable.cmd`, `scripts/*.js`, `scripts/data/`, `scripts/engine-checksums.txt`, `scripts/VERSION`.

**Conventions applied everywhere**
- `${CLAUDE_SKILL_DIR}` → `<skill-base-dir>`; `/impeccable <cmd>` → plain command names.
- "Ask with the AskUserQuestion tool" → "Ask the user"; "sub-agent/Task tool" → "sub-agent tool".
- Shipped subagents → "dispatch a subagent with `reference/degraded/<role>.md`; run inline only when the harness cannot dispatch subagents". The `degraded/*.md` line-2 preambles say the same (their "Generated … Do not edit" line-1 comment is stale).
- Per-file "hand off to polish" lines removed; stated once in SKILL.md.
- History, measurement anecdotes, motivation and aphorisms removed; compatibility facts kept.
- Single homes: contrast (incl. non-text 3:1), component states, scrollbars, 65–75ch → `craft-floor.md`; easing `cubic-bezier(0.16,1,0.3,1)`, durations, no bounce → `animate.md`; breakpoints 640/768/1024/1280 and web touch 44px (WCAG 24px floor) → `adapt.md`; native touch → `ios.md`/`android.md`; P0–P3 → `audit.md`; colour strategies, plates procedure, buildPath → `new-work.md`; empty states → `clarify.md`. Copied command lists → "commands from the SKILL.md table".

**Files**
- `SKILL.md`: rebuilt Overview / When to Use / Core Pattern / Quick Reference / Implementation / Common Mistakes; description gains `Not for …` boundaries (animate, micro-interaction, web-animation-design, 60fps-animation, animation-performance, break-ui, mobile-native, jianyuelab-ui, design-taste-frontend); command table adds pin/hooks/doctor and the `craft`/`teach` aliases.
- Deleted `reference/craft.md` and `reference/operate.md` (content moved to `craft-floor.md` and a "Build depth" section in `mode-operate.md`; `mode-read.md` measure 65–75).
- `scripts/command-metadata.json`: `craft` entry removed; `animate`/`delight` descriptions no longer trigger on generic micro-interaction/hover/animation requests.
- `critique.md`: dangling Codex/"harness gate" text removed; personas from PRODUCT.md; motion depth → improve-animations.
- `new-work.md`: scope note (marketing/company sites from scratch → design-taste-frontend); narrative cut, gates/phases/commands kept.
- `init.md`, `doctor.md`: schema-history narrative cut; `npx impeccable update` → re-vendor per Updating.
- `document.md`: token discovery order `@jianyuelab/tokens` → Tailwind v4 `@theme` → CSS vars → Tailwind v3 → CSS-in-JS; defers to jianyuelab-ui. `extract.md`: targets `@jianyuelab/ui`/`@jianyuelab/tokens`.
- `live.md`, `generate.md`, `hooks.md`: per-harness prose → one table each with an "Other harnesses (e.g. omp)" row. `live-setup.md`: Astro layout path and Astro CSP pattern. `generate.md`: Astro example (`src/pages/index.astro`, :4321).
- `animate.md`, `delight.md`, `overdrive.md`, `quieter.md`, `optimize.md`, `harden.md`, `adapt.md`: generic craft replaced by pointers (animate, choreograph, accessible-animation, animation-performance, 60fps-animation, micro-interaction, emil-design-eng, find-animation-opportunities, apple-design, gsap-web, glassmorphism, remove-animations, break-ui, mobile-native); forced "⚡ OVERDRIVE" banner removed.
- `optimize.md`: React block labelled React only; Astro islands and Vue notes added; Vite visualizer and TanStack Virtual. `harden.md`: `Intl.PluralRules`, no lodash globals, Astro/Vue equivalents.
- `onboard.md`: tour libraries Shepherd.js, Intro.js, Floating UI.

## Updating

```sh
git clone --depth 1 --filter=blob:none --sparse https://github.com/pbakaus/impeccable.git .temp/impeccable
git -C .temp/impeccable sparse-checkout set plugin/skills/impeccable
diff -ru .temp/impeccable/plugin/skills/impeccable skills/impeccable
```

Merge the relevant upstream changes by hand, keeping the local changes above. Always take upstream `scripts/` (engine version, checksums, bundles) as is. Then update the commit and version above.
