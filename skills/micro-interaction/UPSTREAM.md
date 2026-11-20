# Upstream

| | |
|---|---|
| Source | https://github.com/iart-ai/web-animation-skills — `skills/micro-interaction/` |
| Commit | `ed3a045192679b24d32090ee7a983871311ababd` |
| License | MIT |

## Local changes

- Description rewritten from "This skill should be used when…" to triggers plus boundaries (choreograph, page-transition-animation, apple-design).
- Body restructured to the standard shape; principles folded into Quick Reference defaults; Deliver & verify condensed.
- Global reduced-motion CSS block removed (covered by accessible-animation and `references/css-recipes.md`).
- Deleted the empty `README.md`.
- Removed the dangling "Packaged helper (`scripts/`)" note; no `scripts/` directory ships with this skill.
- `npx playwright` examples changed to `bunx playwright`.
- Motion values aligned with animate (single home for easing, duration, springs): exits ease-out and ~20% faster instead of ease-in; easing curves replaced by animate's `--ease-out` / `--ease-overshoot` (dropped `cubic-bezier(0.4, 0, 0.2, 1)` and `cubic-bezier(0.16, 1, 0.3, 1)`); laggy threshold ~400ms → 300ms; enter/exit CSS `ease` → `var(--ease-out)`; description gains the animate boundary.
- Springs converted from stiffness/damping to `{ type: "spring", duration, bounce }` in SKILL.md and `references/framer-motion-recipes.md`, keeping the feel (bounce ≈ 1 − damping ratio, animate's rule): press 400/30 → `duration: 0.3, bounce: 0.25`; layout and toast stack 500/40 → `duration: 0.35, bounce: 0.1`; stagger item 500/30 → `duration: 0.3, bounce: 0.33`. An earlier pass had flattened all of them to `bounce: 0`. The stiffness/damping explanation removed. `dragTransition` keeps `bounceStiffness`/`bounceDamping` (inertia options only; no duration/bounce form), noted in the code.
- Layout and toast stack springs `bounce: 0.1` → `bounce: 0` (SKILL.md, `references/framer-motion-recipes.md`): animate's rule that everyday UI uses bounce 0.
- Standalone demo harness code replaced by a pointer to animate `references/standalone-harness.md`; the state check list stays.
- SKILL.md Common Mistakes: dropped the exit/`AnimatePresence`, toast `popLayout` and demo-screenshot rows (stated in Core Pattern and Standalone demo); references list updated.
- `references/css-recipes.md`: `:hover` lift gated by `@media (hover: hover) and (pointer: fine)`; press override 0.06s → 0.1s (animate's 100–160ms); accordion `0.3s ease` → `0.2s var(--ease-out)`; `[popover]` gains a trigger-facing `transform-origin`; global `0.01ms` reduced-motion reset replaced by a pointer to accessible-animation.
- `references/framer-motion-recipes.md`: `staggerChildren`/`delayChildren`/`staggerDirection` → `delayChildren: stagger(0.06, { startDelay: 0.1 })` and `stagger(…, { from: "last" })`, with the legacy names kept as a note; like-button `whileTap` 0.85 → 0.95 (press range 0.95–0.98); `ease: "easeOut"` → `[0.23, 1, 0.32, 1]`; garbled AnimatePresence clause removed; reduced-motion code replaced by a pointer to accessible-animation (the `MotionConfig` fact kept); iart.ai footer removed.
- Curve tokens in code carry a literal fallback (copy-paste safe without animate's :root tokens).
- SKILL.md toast: exit transition repeats ease (`[0.23, 1, 0.32, 1]`), since an `exit.transition` replaces the component-level transition.
- Everyday UI springs (press, list stagger) use bounce 0; converted bounce kept only for drag and playful motion.
