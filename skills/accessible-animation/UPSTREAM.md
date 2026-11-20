# Upstream

| | |
|---|---|
| Source | https://github.com/iart-ai/web-animation-skills — `skills/accessible-animation/` |
| Commit | `ed3a045192679b24d32090ee7a983871311ababd` |
| License | MIT |

## Local changes

- Description rewritten to triggers plus boundaries (glassmorphism, improve-animations).
- Body restructured to the standard shape; tiers and WCAG mapping as tables; Gotchas merged into Common Mistakes; Deliver & verify condensed.
- Deleted the empty `README.md`.
- Removed the dangling "Packaged helper (`scripts/`)" note; no `scripts/` directory ships with this skill.
- `npx playwright` examples changed to `bunx playwright`.
- Standalone-demo harness script and playwright commands replaced by a pointer to animate's `references/standalone-harness.md`; the both-paths rule (`?reduce=1`, `--reduced-motion=reduce`) and the confirm list stay.
- Description gains the animate boundary (easing/duration).
- Core Pattern tier table and Quick Reference motion table merged into one per-motion table in Core Pattern (every Tier 1/2/3 example and reduced behavior kept); Quick Reference keeps the WCAG table.
- Common Mistakes: dropped the `0s` and `animation-iteration-count: 1` rows (explained in the global safety-net CSS comments).
- Lenis snippets (SKILL.md, `references/patterns.md`) note that with GSAP/ScrollTrigger Lenis runs from `gsap.ticker` as in gsap-web, not its own rAF loop.
- `framer-motion` imports → `motion/react` (SKILL.md, `references/patterns.md`).
- References line names the wrapper by its real name, `createMotionController` (was "`animateWithMotionPreference`").
- `references/patterns.md`: iart.ai footer removed.
- Reduced-motion CSS path uses the harness `emulateMedia` script (the CLI flag does not exist).
