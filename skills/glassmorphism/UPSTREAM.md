# Upstream

| | |
|---|---|
| Source | https://github.com/iart-ai/web-animation-skills — `skills/glassmorphism/` |
| Commit | `ed3a045192679b24d32090ee7a983871311ababd` |
| License | MIT |

## Local changes

- Description rewritten to triggers plus boundaries (svg-animation, design-taste-frontend, impeccable).
- Body restructured to the standard shape; frost tiers and refraction knobs as tables; Deliver & verify condensed; 2026 / evolution framing removed.
- Deleted the empty `README.md`.
- Removed the dangling "Packaged helper (`scripts/`)" note; no `scripts/` directory ships with this skill.
- `npx playwright` examples changed to `bunx playwright`.
- Standalone-deliverable script and playwright commands (SKILL.md) and the freeze-harness script (`references/glass-recipes.md` §8) replaced by a pointer to animate's `references/standalone-harness.md`; glass-specific state/time targets, `:root[data-state]` CSS hook and confirm list stay. `?reduced=1` renamed to the harness's `?reduce=1`.
- Hover transform curve `cubic-bezier(.16,1,.3,1)` replaced with animate's `--ease-out` value `cubic-bezier(0.23, 1, 0.32, 1)` (SKILL.md and glass-recipes.md).
- Hover (SKILL.md and recipes §4): 0.4s → 0.2s, gated with `@media (hover: hover) and (pointer: fine)`; color properties keep `ease` (animate's hover row), transform uses `var(--ease-out)`. Entrance `0.5s/0.6s ease` → `var(--ease-out)`.
- Specular sweep animates `transform: translateX()` instead of `left` (same travel: 340% of the 50%-wide glint = the old −60% → 110%), on `var(--ease-in-out)`; SKILL.md notes "never `left`".
- SKILL.md Accessibility: the CSS block became short rules plus a pointer to recipes §7, which keeps the full fallback CSS. Recipes §6 Performance bullets, the §7 contrast bullets and the §8 harness text became pointers to SKILL.md (the "leaving `will-change` on wastes memory" detail and "rest / hover / enter" moved into SKILL.md). "Radii >40px" clarified to blur radii.
- SKILL.md Confirm sentence split into bullets; Common Mistakes dropped the Safari-prefix, hover-jank and nested-blur rows (already in Quick Reference and Implementation).
- Recipes: preamble trimmed; leftover "(the 2026 look)" removed; iart.ai footer removed.
- Curve tokens in code carry a literal fallback (copy-paste safe without animate's :root tokens).
- SKILL.md Core Pattern: the base `.glass` CSS block (a copy of recipes §1) replaced by a pointer; the four rules and the tier table stay.
