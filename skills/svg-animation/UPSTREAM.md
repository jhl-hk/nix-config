# Upstream

| | |
|---|---|
| Source | https://github.com/iart-ai/web-animation-skills — `skills/svg-animation/` |
| Commit | `ed3a045192679b24d32090ee7a983871311ababd` |
| License | MIT |

## Local changes

- Description rewritten to triggers plus boundaries (gsap-web, glassmorphism, micro-interaction).
- Body restructured to the standard shape; Deliver & verify condensed.
- Deleted the empty `README.md`.
- Removed the dangling "Packaged helper (`scripts/`)" note; no `scripts/` directory ships with this skill.
- `npx playwright` examples changed to `bunx playwright`.
- Standalone-deliverable `?t=N` script and playwright command replaced by a pointer to animate's `references/standalone-harness.md`; the screenshot/confirm list stays.
- Draw-on and hamburger curves: plain `ease` → animate's tokens (`var(--ease-in-out)` for draw-on and the line transforms, `var(--ease-out)` for the fading middle line).
- Common Mistakes cut to the SVGO row and the filter row; the other four restated Core Pattern and Implementation. "Animate filters sparingly" replaced by a concrete fix (static filter, animate `transform`/`opacity` on the filtered layer).
- `references/svg-techniques.md`: `getTotalLength` example forces a style flush (`getBoundingClientRect()`) instead of relying on one `requestAnimationFrame`; Flubber + Motion example hoists `interpolate(A, B)` out of the per-frame transform and drops the identity `useTransform`; "GSAP ~JS" bundle cell rewritten; stale "Reach (legacy IE/Edge)" table row deleted (the SMIL/IE note stays in SKILL.md); iart.ai footer removed.
- Curve tokens in code carry a literal fallback (copy-paste safe without animate's :root tokens).
