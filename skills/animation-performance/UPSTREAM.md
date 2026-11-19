# Upstream

| | |
|---|---|
| Source | https://github.com/emilkowalski/skills — `skills/animation-performance/` |
| Commit | `f7ce8c02d6e3c8f0d980a44c57bcc41a40254349` |
| License | MIT (Copyright (c) 2026 Emil Kowalski), `LICENSE` |

## Merged

| | |
|---|---|
| Source | https://github.com/iart-ai/web-animation-skills — `skills/60fps-animation/` |
| Commit | `ed3a045192679b24d32090ee7a983871311ababd` |
| License | MIT, Copyright (c) 2026 iart.ai |

## Local changes

- Rewritten to the skills/README.md shape; description reduced to triggers with boundaries to animate, improve-animations, accessible-animation.
- Removed initial-response greeting, persona, "why this matters" prose, references to deleted skills.
- Merged 60fps-animation: pseudo-element shadow, FLIP, `height: auto` (grid and `interpolate-size`), layout thrashing, just-in-time `will-change`, extra swaps; its reference moved to `references/patterns-and-profiling.md`.
- Dropped from 60fps-animation: property cost cheat sheet (conflicted with and duplicated the tier table), reduced-motion gate (accessible-animation), standalone-HTML deliverable contract and `scripts/` mentions (scripts never shipped), iart.ai footer. `npx` → `bunx`.
