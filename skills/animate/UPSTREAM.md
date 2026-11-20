# Upstream

| | |
|---|---|
| Source | https://github.com/emilkowalski/skills — `skills/animate/` |
| Commit | `f7ce8c02d6e3c8f0d980a44c57bcc41a40254349` |
| License | MIT (`LICENSE`) |

| | |
|---|---|
| Source | https://github.com/vercel-labs/open-agents — `.agents/skills/web-animation-design/` |
| Commit | `cf865e94de7729751c747171785b6ce57e7b178c` |
| License | MIT (`LICENSE-web-animation-design`) |

## Local changes

- Merged web-animation-design into this skill; its directory is removed.
- SKILL.md restructured to the README shape; description rewritten to triggers plus boundaries.
- Removed the canned initial response, operating-posture prose and references to deleted skills (review-animations, find-animation-opportunities, animate-expo, pick-ui-library).
- Added from web-animation-design: ease-out/ease-in-out curve families, paired-elements rule, duration scaling and ~20% faster exits, marketing vs product, React render-cycle and blur limits.
- web-animation-design `PRACTICAL-TIPS.md` moved to `references/practical-tips.md`, trimmed to tips not already in SKILL.md.
- Dropped from web-animation-design: the Before/After review-format rule (reviews belong to improve-animations); "disable all motion, no exceptions" reduced-motion rule (conflicts with "gentler, not zero"; accessible-animation owns it); claim that Motion `x` is never hardware accelerated (superseded by Motion 14.2); ASCII easing flowchart (duplicates the easing table); course URL `/learn/easing-curves`.
- Added the `--ease-overshoot` token (from micro-interaction) and spring starting points as duration/bounce; animate is the single home for easing curves, duration limits and spring config.
- Added `references/standalone-harness.md`, merged from the screenshot harnesses in accessible-animation, gsap-web, svg-animation, glassmorphism, micro-interaction, page-transition-animation and animation-performance; those skills now point here.
- Description boundaries rewritten as `Not for X; use <skill>.` and extended to every neighbour (page-transition-animation, gsap-web, svg-animation, accessible-animation); the duplicate `Not for:` line in When to Use removed. "Make a component feel alive" stays here only; improve-animations dropped it.
- Overview preamble ("passes a strict review the first time") cut.
- Body reshaped: Quick Reference holds the lookup tables (frequency, tool, easing with tokens and families, duration, springs); Implementation holds the nine decision steps, which point at those tables, plus recipes/references and output.
- Purposes gained improve-animations' examples (press scale, hold-to-confirm fill, same-edge toast, panel from trigger, morphing button, expanding accordion) and "it looks cool is not a purpose"; improve-animations now points here for the list.
- Springs: added the stiffness/damping → duration/bounce conversion rule (bounce ≈ 1 − damping ratio) that the other motion skills follow.
- Common Mistakes: dropped the `scale(0)`, `ease-in` and keyboard/100+/day rows (stated in Core Pattern).
- RECIPES.md: preamble cut; scroll reveal and the WAAPI clip reveal use `--ease-out` instead of `--ease-in-out` (entrances ease out); tooltip gains "Radix UI and Base UI set `data-instant`"; blur crossfade gains the press variant (scale + blur, 150ms `--ease-out`) from practical-tips.
- `references/practical-tips.md`: the tooltip and blur blocks (copies of RECIPES with built-in `ease-out`) replaced by pointers to RECIPES; tap-target minimum split by source (Apple 44pt, WCAG 2.5.8 AA 24px, WCAG 2.5.5 AAA 44px); `@utility touch-hitbox::before` (not a valid Tailwind v4 utility name) nested as `&::before` inside `@utility touch-hitbox`.
- Spring conversion rule: everyday UI exception (bounce 0).
- Harness: invalid `--reduced-motion` CLI flag replaced by an `emulateMedia` script (verified); `file://` CORS note for ES modules.
