---
name: accessible-animation
description: Use when respecting prefers-reduced-motion, making animations accessible, fixing vestibular or motion-sickness reports, writing a useReducedMotion hook, gating GSAP (gsap.matchMedia), Framer Motion (MotionConfig reducedMotion), Lenis smooth scroll, CSS keyframes or canvas/WebGL for reduced motion, or meeting WCAG 2.3.3 / C39 / 2.2.2 for animation. Not for reduced-transparency glass fallbacks; use glassmorphism. Not for auditing every animation in a codebase; use improve-animations. Not for choosing easing or duration; use animate.
version: 0.1.0
---

# Accessible Animation (Reduced Motion, Tiered)

## Overview

Honor `prefers-reduced-motion: reduce` as graceful degradation, not a kill switch: remove vestibular-triggering motion, keep orientation cues. Removing *all* motion over-corrects — elements teleport and affordances (focus rings, progress spinners) vanish.

The OS setting: macOS Settings > Accessibility > Display > Reduce motion; Windows Settings > Accessibility > Visual effects > Animation effects; iOS/Android equivalents.

## When to Use

- Adding or auditing motion in a web UI
- A user reports motion sickness, or a WCAG finding
- Integrating GSAP, Framer Motion, Lenis, Anime.js, CSS keyframes, canvas/WebGL into an accessible product

## Core Pattern

Sort every animation into a tier: **1 — Remove** (vestibular triggers), **2 — Soften**, **3 — Keep**.

| Motion | Tier | Reduced behavior |
|---|---|---|
| Parallax / depth | 1 | Remove (`transform: none`) |
| Large-area slide / translate | 1 | Remove or replace with fade |
| Scale / zoom of large elements | 1 | Remove |
| Spin / 3D rotation | 1 | Remove (`animation: none`) |
| Auto-playing carousel / marquee | 1 | Stop + provide pause control (2.2.2) |
| Smooth-scroll hijacking (Lenis/Locomotive) | 1 | Don't instantiate |
| Scroll-jacked pinned scenes, motion paths, anything moving much of the screen or implying depth/self-motion | 1 | Remove |
| Small slide / pop-in | 2 | Short opacity fade ≤200ms: strip displacement, keep the fact of a transition (600ms slide-in → 150ms cross-fade) |
| Opacity fade | 3 | Keep (shorten if long) |
| Color / background / focus-ring transition | 3 | Keep |
| Loading indicator | 3 | Keep (essential feedback) |
| Motion essential to meaning | 3 | Keep |

## Quick Reference

WCAG:

| Criterion | Requirement |
|---|---|
| 2.3.3 Animation from Interactions (AAA) | Interaction-triggered motion (scroll, hover) can be disabled unless essential; honoring `prefers-reduced-motion` is the standard technique |
| C39 (CSS technique) | `prefers-reduced-motion` query; the named sufficient technique |
| 2.2.2 Pause, Stop, Hide (A) | Auto-playing motion >5s needs pause/stop regardless of the media query |

## Implementation

### CSS

Global safety net (backstop only):

```css
/* 0.01ms, not 0s: 0s can break JS waiting for transitionend/animationend. */
@media (prefers-reduced-motion: reduce) {
  *,
  *::before,
  *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;   /* stop infinite spins/marquees */
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;          /* kill smooth scroll */
  }
}
```

Layer tiered overrides so Tier 3 survives:

```css
.card {
  transition: transform 400ms ease, opacity 400ms ease, background-color 200ms ease;
}

@media (prefers-reduced-motion: reduce) {
  .card {
    /* Tier 2: drop the transform, keep opacity + color (Tier 3) */
    transition: opacity 150ms ease, background-color 150ms ease;
  }
  .parallax-layer { transform: none !important; }        /* Tier 1 */
  .hero-zoom      { animation: none !important; }        /* Tier 1 */
}
```

For elaborate effects, opt motion IN with the positive query:

```css
.hero { opacity: 1; } /* visible, static by default */
@media (prefers-reduced-motion: no-preference) {
  .hero { animation: zoom-in 1.2s ease both; }
}
```

### JS

CSS can't gate GSAP, Framer's `animate`, canvas/WebGL or Lenis. Read the same signal and listen for live changes (toggling the OS setting doesn't reload the page):

```js
const REDUCE_QUERY = '(prefers-reduced-motion: reduce)';

export function prefersReducedMotion() {
  return typeof window !== 'undefined'
    && window.matchMedia
    && window.matchMedia(REDUCE_QUERY).matches;
}

export function onReducedMotionChange(cb) {
  const mq = window.matchMedia(REDUCE_QUERY);
  const handler = (e) => cb(e.matches);
  mq.addEventListener('change', handler);
  return () => mq.removeEventListener('change', handler);
}
```

```js
// GSAP — matchMedia() reverts conditional setups on change.
import gsap from 'gsap';
const mm = gsap.matchMedia();
mm.add({
  motionOK: '(prefers-reduced-motion: no-preference)',
  motionReduce: '(prefers-reduced-motion: reduce)',
}, (ctx) => {
  const { motionOK } = ctx.conditions;
  if (motionOK) {
    gsap.from('.hero', { y: 80, opacity: 0, duration: 1 });   // Tier 1 move
  } else {
    gsap.from('.hero', { opacity: 0, duration: 0.15 });        // Tier 2 fade
  }
});

// Lenis — do not instantiate when reduced. With GSAP/ScrollTrigger on the page,
// drive Lenis from gsap.ticker as in gsap-web instead of this rAF loop.
import Lenis from 'lenis';
let lenis = null;
if (!prefersReducedMotion()) {
  lenis = new Lenis();
  const raf = (t) => { lenis.raf(t); requestAnimationFrame(raf); };
  requestAnimationFrame(raf);
}
```

### React hook

```jsx
import { useState, useEffect } from 'react';

export function useReducedMotion() {
  const query = '(prefers-reduced-motion: reduce)';
  const get = () =>
    typeof window !== 'undefined' && window.matchMedia
      ? window.matchMedia(query).matches
      : false;
  const [reduced, setReduced] = useState(get);

  useEffect(() => {
    const mq = window.matchMedia(query);
    const onChange = () => setReduced(mq.matches);
    onChange();                                   // sync after hydration
    mq.addEventListener('change', onChange);
    return () => mq.removeEventListener('change', onChange);
  }, []);

  return reduced;
}
```

```jsx
// Framer Motion has its own useReducedMotion(); the hook above also works.
import { motion } from 'motion/react';
function Card() {
  const reduced = useReducedMotion();
  return (
    <motion.div
      initial={reduced ? { opacity: 0 } : { opacity: 0, y: 40 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: reduced ? 0.15 : 0.5 }}
    />
  );
}
```

SSR: initialize to `false` (motion) and re-sync in `useEffect`; the OS value is client-only.

### Standalone demo

One HTML file with full motion AND tiered overrides; build motion conditionally on `reduce` (Tier 1 removed, Tier 2 softened, Tier 3 kept). Freeze frames with the harness in animate (`references/standalone-harness.md`). Screenshot **both** paths at the same mid-animation `?t=`: `?reduce=1` forces the JS path; the harness's `emulateMedia` script emulates the preference for the CSS layer.

Confirm mid-animation in both: Tier 1 gone, Tier 2 a short fade, Tier 3 kept; no teleporting; >5s auto-motion has a pause control; reduced fades ≤200ms.

### References

- `references/patterns.md` — read for GSAP `matchMedia` teardown, Framer Motion `MotionConfig`, Lenis start/stop on live toggle, a `createMotionController` wrapper (picks full/reduced variants, live-reactive), marquee with pause control, a tier-classification audit checklist.

## Common Mistakes

| Mistake | Fix |
|---|---|
| Global `*` reset alone | Over-removes Tier 3; layer intentional overrides |
| JS/canvas/WebGL ungated | `matchMedia`, or the loop never stops |
| No `change` listener | Page keeps stale state after OS toggle |
| `matchMedia` during SSR render | Default to motion, sync in an effect |
| Marquee relies on the media query | Visible pause control even with motion on (2.2.2, Level A) |
