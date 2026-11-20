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
- `cubic-bezier(0.2, 0, 0, 1)` replaced by animate's `--ease-out` (`var(--ease-out)` in CSS, its literal `cubic-bezier(0.23, 1, 0.32, 1)` in WAAPI) in SKILL.md and `references/patterns-and-profiling.md`.
- Headless-verification freeze code (`?t=N` for `@keyframes` and WAAPI, `bunx playwright screenshot`) moved to animate `references/standalone-harness.md`; the reference keeps a pointer and its own check list. The Vaul `--swipe-amount` story stays here as its single home.
- When to Use: dropped the "Not for" line repeating the description.
- Symptoms table removed: each row was a step of the diagnosis order; the fixes it carried (ref/motion value, `motion` 14.2+ or full `transform` string, blur <20px or cross-fade, batch reads then writes, `will-change` only once seen, Safari blur note) were folded into the ordered list, the `transition: all` row is rule 4, the shadow row is the Swaps table.
- Common Mistakes cut to the scroll-handler row; the others restated rules 3 and 5, the `scaleX` note, the grid-collapse comment and the Swaps table.
- Vercel tab-indicator anecdote moved to `## Real-World Impact`.
- `height: auto` examples (SKILL.md) and the accordion in `references/patterns-and-profiling.md`: 300ms `ease` / 280ms → 200ms `var(--ease-out)` (animate's accordion value).
- `references/patterns-and-profiling.md`: the CDP-trace sentence (a copy of the harness file's last bullet) became a pointer.
- Curve tokens in code carry a literal fallback (copy-paste safe without animate's :root tokens).
- Motion 14.2 shorthand snippet (a copy of animate SKILL.md step 4) replaced by a pointer; the "before 14.2: main thread" sentence kept.
