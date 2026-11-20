# Upstream

| | |
|---|---|
| Source | https://github.com/iart-ai/web-animation-skills — `skills/gsap-web/` |
| Commit | `ed3a045192679b24d32090ee7a983871311ababd` |
| License | MIT |

## Local changes

- Description rewritten to triggers plus boundaries (choreograph, svg-animation, accessible-animation, animation-performance).
- Body restructured to the standard shape; position parameters, easing and Lenis symptoms as tables; Deliver & verify condensed; performance points to animation-performance.
- Deleted the empty `README.md`.
- Removed the dangling "Packaged helper (`scripts/`)" note; no `scripts/` directory ships with this skill.
- `npx playwright` examples changed to `bunx playwright`.
- Standalone-deliverable `?t=N` script and playwright command replaced by a pointer to animate's `references/standalone-harness.md`; the screenshot/confirm list and `examples/standalone-template.html` stay.
- "Since GSAP 3.12" corrected to 3.13 (the release that made every plugin free).
- Lenis wiring: the ticker callback is named (`update`) so `gsap.ticker.remove(update)` works; teardown shown in code. SKILL.md holds the one canonical wiring and the merged symptom table; `references/scrolltrigger-lenis.md` lost its duplicate canonical block, recap, cleanup block, debugging checklist and symptom table (all facts merged into SKILL.md) and keeps Locomotive, refresh/resize, `data-lenis-prevent`, anchors, the reduced-motion gate and the React example; the `useEffect` variant became a one-line delta. Locomotive recipe labelled v4.
- Easing table maps animate's tokens to GSAP (`power4.out`, `power3.inOut`, `CustomEase`, `back.out(1.7)`); Flip example `power2.inOut` → `power3.inOut`.
- Common Mistakes table removed; every row restated a rule already in Implementation.
- Staggers 0.1–0.12s → 0.06s (animate's 30–80ms) in the cookbook and the hero example.
- Cookbook batch reveal: fixed `gsap.set(autoAlpha 0)` + `gsap.from(autoAlpha 0)` (tweens 0 → 0, cards never appear) to `gsap.to` the visible state; added `once: true`; replay via `onLeaveBack` marked opt-in.
- `examples/hero-timeline.js`: install `bun add gsap` (dropped the unused `@gsap/react`); fixed the same set-then-from bug (elements and the `.hero__actions` container stayed hidden) with a CSS `visibility: hidden` prerequisite; timeline targets scoped through `q()` so `root` is honoured; reduced motion is a 0.2s `autoAlpha` fade instead of an instant set.
- `examples/standalone-template.html`: reads `?reduce=1` and `?state` as the harness defines (CTA hover hook gated by `(hover: hover)`); reduced motion is a 0.2s opacity fade instead of an instant set.
- Removed the iart.ai footer from `references/scrolltrigger-lenis.md`.
