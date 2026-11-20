# Upstream provenance

Vendored, not tracked as a flake input.

| | |
|---|---|
| Source | https://github.com/pbakaus/impeccable — `plugin/skills/impeccable/` |
| Commit | `d34c87e1a00989ae8dbdd7f6b30b70f23319e860` |
| Version | 4.8.0 |
| License | Apache-2.0 (© Paul Bakaus); `LICENSE` copied from the repo root at the commit above |

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
- "Ask with the AskUserQuestion tool" → "Ask the user"; "sub-agent/Task tool" → "dispatch a subagent" / "cannot dispatch subagents"; "sub-agent" spelled "subagent".
- Shipped subagents → "dispatch a subagent with `reference/degraded/<role>.md`; run inline only when the harness cannot dispatch subagents". The `degraded/*.md` line-2 preambles say the same (their "Generated … Do not edit" line-1 comment is stale).
- Per-file "hand off to polish" lines removed; stated once in SKILL.md.
- History, measurement anecdotes, motivation and aphorisms removed; compatibility facts kept.
- Single homes: contrast (incl. non-text 3:1), component states, scrollbars, 65–75ch → `craft-floor.md`; motion durations, curves and springs → the animate skill (upstream's `cubic-bezier(0.16,1,0.3,1)` house easing and its "no bounce or elastic curves" rule dropped: animate allows bounce 0.1–0.3 for drag and playful motion); breakpoints 640/768/1024/1280 and web touch 44px (WCAG 24px floor) → `adapt.md`; native touch → `ios.md`/`android.md`; P0–P3 → `audit.md`; colour strategies, plates procedure, buildPath → `new-work.md`; empty states → `clarify.md`. Copied command lists → "commands from the SKILL.md table".

**Files**
- `SKILL.md`: rebuilt Overview / When to Use / Core Pattern / Quick Reference / Implementation / Common Mistakes; description gains compact `Not for …` boundaries (animate, micro-interaction, animation-performance, break-ui, mobile-native, jianyuelab-ui, design-taste-frontend), mirrored by the When to Use table; jianyuelab-ui marked **REQUIRED SUB-SKILL** for `@jianyuelab/*` projects; command table adds pin/hooks/doctor and the `craft`/`teach` aliases.
- Deleted `reference/craft.md` and `reference/operate.md` (content moved to `craft-floor.md` and a "Build depth" section in `mode-operate.md`; `mode-read.md` measure 65–75).
- `scripts/command-metadata.json`: `craft` entry removed; `animate`/`delight` descriptions no longer trigger on generic micro-interaction/hover/animation requests.
- `critique.md`: dangling Codex/"harness gate" text removed; personas from PRODUCT.md; motion depth → improve-animations. The subagent mandate and degraded banner stated once in Hard Invariants; the subagent gate and report header carry procedure only. The withheld-prose note scoped to harnesses that withhold prose after a structured question.
- `new-work.md`: scope note (marketing/company sites from scratch → design-taste-frontend); narrative cut, gates/phases/commands kept.
- `init.md`, `doctor.md`: schema-history narrative cut; `npx impeccable update` → re-vendor per Updating.
- `document.md`: token discovery order `@jianyuelab/tokens` → Tailwind v4 `@theme` → CSS vars → Tailwind v3 → CSS-in-JS; defers to jianyuelab-ui. Sidecar example motion token `ease-standard` (0.4,0,0.2,1) → animate's `ease-out` (0.23,1,0.32,1). `extract.md`: targets `@jianyuelab/ui`/`@jianyuelab/tokens`.
- `live.md`, `generate.md`, `hooks.md`: per-harness prose → one table each with an "Other harnesses (e.g. omp)" row. `live-setup.md`: Astro layout path and Astro CSP pattern. `generate.md`: Astro example (`src/pages/index.astro`, :4321).
- `animate.md`, `delight.md`, `overdrive.md`, `quieter.md`, `optimize.md`, `harden.md`, `adapt.md`: generic craft replaced by pointers (animate, choreograph, accessible-animation, animation-performance, micro-interaction, emil-design-eng, improve-animations Find and Remove modes, apple-design, gsap-web, glassmorphism, break-ui, mobile-native); forced "⚡ OVERDRIVE" banner removed.
- `reference/animate.md`: duration table and easing rules replaced by a pointer to the animate skill (single home for motion values); 500–800 ms focal entrance kept. `craft-floor.md`, `quieter.md`, `mode-operate.md`: easing and duration pointers go to the animate skill instead of `animate.md`; craft-floor's "exponential ease-out" → animate's `--ease-out`.
- `optimize.md`: React block labelled React only; Astro islands and Vue notes added; Vite visualizer and TanStack Virtual. `harden.md`: `Intl.PluralRules`, no lodash globals, Astro/Vue equivalents; `.wrap` uses `overflow-wrap: anywhere` (was `break-word`), matching break-ui.
- `layout.md`, `typeset.md`: "When a sub-agent tool is available and permitted" → "When you can dispatch subagents". `degraded/documenter.md`, `degraded/finish-reviewer.md`: "Reads" → "reads".
- `onboard.md`: tour libraries Shepherd.js, Intro.js, Floating UI.

## Updating

```sh
git clone --depth 1 --filter=blob:none --sparse https://github.com/pbakaus/impeccable.git .temp/impeccable
git -C .temp/impeccable sparse-checkout set plugin/skills/impeccable
diff -ru .temp/impeccable/plugin/skills/impeccable skills/impeccable
```

Merge the relevant upstream changes by hand, keeping the local changes above. Always take upstream `scripts/` (engine version, checksums, bundles) as is. Then update the commit and version above.
