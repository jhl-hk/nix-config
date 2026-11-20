# Upstream

| | |
|---|---|
| Source | https://github.com/emilkowalski/skills — `skills/apple-design/` |
| Merged source | https://github.com/emilkowalski/skills — `skills/gestures/` (MIT, same LICENSE) |
| Commit | `f7ce8c02d6e3c8f0d980a44c57bcc41a40254349` (both) |
| License | MIT |
| Upstream sources (moved from SKILL.md) | Apple WWDC talks — *Designing Fluid Interfaces* (2018), *Designing Audio-Haptic Experiences*, *The Details of UI Typography* (2020), *Principles of Great Design* (2026) — translated to CSS, Pointer Events, `requestAnimationFrame` and Motion / Framer Motion |

## Local changes

- Merged `gestures` into this skill; `skills/gestures/` removed.
- Description rewritten as triggers plus boundaries to animate, glassmorphism, accessible-animation, animation-performance.
- Body restructured to Overview / When to Use / Core Pattern / Quick Reference / Implementation / Common Mistakes.
- Removed the "Initial Response" canned reply, quotes, motivation and duplicated rules.
- Removed the `pick-ui-library` reference.
- Vaul sheet and small-drawer curves cite animate's `--ease-drawer` and quart ease-out instead of standing alone.
- The parent-CSS-variable lag story (Vaul past ~20 items) reduced to one rule with a pointer to animation-performance, which keeps the story.
- Typography, design principles (with tactical rules) and process moved verbatim to `references/typography-principles-process.md`; SKILL.md keeps a References pointer.
- §13 Materials and depth moved verbatim to `references/materials-and-accessibility.md`; SKILL.md keeps a one-paragraph pointer plus the glassmorphism pointer.
- §15 reduced motion keeps the gesture rule (tracking stays; reduce flings, bounce, decoration); the signal table, vestibular hazards and CSS moved verbatim to `references/materials-and-accessibility.md`; points to accessible-animation for the rest.
- Track/release mermaid chart removed; its content (no easing/duration/spring while tracking, velocity-seeded spring and never a keyframe on release) folded into the Overview.
- "Source:" provenance line moved to the table above.
- Spring table gained a Motion `bounce`/`duration` column (bounce ≈ 1 − damping ratio, animate's conversion rule; duration ≈ response).
- Press feedback stated once (§1 code; the Values row removed); its curve `ease-out` → `var(--ease-out)`.
- Common Mistakes table removed: every row restated a Core Pattern row, a Values row or an Implementation rule.
- Curve tokens in code carry a literal fallback (copy-paste safe without animate's :root tokens).
