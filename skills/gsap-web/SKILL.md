---
name: gsap-web
description: Use when building GSAP motion — timelines, hero entrance timelines, ScrollTrigger (pin, scrub, horizontal scroll, snap, batch, parallax), scroll-driven storytelling, SplitText word/line reveals, Flip layout changes, quickTo pointer follow — or when Lenis/Locomotive smooth scroll is jittery, ScrollTrigger markers drift, or pins break with Lenis/Locomotive. Not for ordering decisions between elements; use choreograph. Not for MorphSVG/MotionPath on SVG; use svg-animation. Not for reduced-motion policy; use accessible-animation.
version: 0.1.0
---

# GSAP for the Web

## Overview

GSAP drives code-driven web motion: sequenced timelines, scroll-driven scenes, text reveals and layout transitions. Since GSAP 3.12 every plugin (ScrollTrigger, SplitText, Flip, MotionPath, MorphSVG, Draggable, Observer, CustomEase) is free, including commercial use.

## When to Use

- Pinned sections, parallax, progress scrubbing, horizontal scroll
- Sequenced hero animations and multi-element timelines with precise overlap
- Text split into chars/words/lines (SplitText)
- Elements changing position/size/parent (Flip)
- Motion needing fine timing, easing precision or imperative orchestration

## Core Pattern

| Before | After |
|---|---|
| Many independent tweens with delays | One timeline with position parameters: single playhead, reversible |
| `opacity: 0` | `autoAlpha: 0` (also `visibility:hidden`, removed from hit-testing) |
| `mousemove` → new tween each event | `gsap.quickTo` |
| One trigger per reveal | `ScrollTrigger.batch()` |
| Tweens left alive on SPA unmount | `gsap.context()` / `useGSAP`, `ctx.revert()` |

## Quick Reference

| Goal | API |
|------|-----|
| Sequence with overlap | `tl.from(...).from(..., "-=0.3")` |
| Pin while scrolling | `scrollTrigger:{ pin:true, end:"+=N" }` |
| Scrub to scroll | `scrollTrigger:{ scrub:1, ease:"none" }` |
| Reveal lines of text | `SplitText.create(el,{type:"lines"})` |
| Animate layout change | `Flip.getState` → mutate → `Flip.from` |
| Fast pointer follow | `gsap.quickTo(el,"x",{...})` |
| Kill everything | `ScrollTrigger.getAll().forEach(t=>t.kill())` |

Position parameter:

| Value | Meaning |
|---|---|
| `"+=0.5"` / `"-=0.3"` | Relative to timeline end (gap / overlap) |
| `"<"` / `">"` | Start / end of previous tween |
| `"<0.2"` | 0.2s after previous tween's start |
| `"myLabel"` | Label from `tl.addLabel("myLabel")` |

Easing:

| Ease | Use |
|---|---|
| `power2/3.out` | Entrances |
| `power2.inOut` | Moves between two on-screen states |
| `back.out(1.7)` | Overshoot/pop (number = overshoot) |
| `elastic.out(1, 0.3)` | Bouncy, sparingly |
| `none` | Scrubbed scroll tweens |
| `steps(n)` | Sprite/stepped motion |
| `CustomEase.create("x", "M0,0 C0.2,0 0,1 1,1")` | Custom cubic-bezier |

## Implementation

### Register

```js
import gsap from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";
import { SplitText } from "gsap/SplitText";
import { Flip } from "gsap/Flip";

gsap.registerPlugin(ScrollTrigger, SplitText, Flip);
```

Unregistered plugins silently no-op. With a bundler, register once at app entry.

### Timelines

```js
const tl = gsap.timeline({ defaults: { ease: "power3.out", duration: 0.6 } });
tl.from(".title", { yPercent: 100, opacity: 0 })
  .from(".sub",   { y: 20, opacity: 0 }, "-=0.3")  // start 0.3s before prev ends
  .from(".cta",   { scale: 0.9, opacity: 0 }, "<"); // align to prev tween START
```

`.from()` for entrances (from given values to current CSS), `.to()` for exits, `.fromTo()` when both ends must be explicit (most robust against re-runs).

```js
gsap.set(el, { autoAlpha: 0 });           // instant, no tween
const xTo = gsap.quickTo(el, "x", { duration: 0.4, ease: "power3" });
window.addEventListener("pointermove", (e) => xTo(e.clientX));
```

### ScrollTrigger

```js
gsap.to(".panel", {
  xPercent: -100,
  ease: "none",
  scrollTrigger: {
    trigger: ".wrap",
    start: "top top",      // when trigger top hits viewport top
    end: "+=2000",         // 2000px of scroll distance
    pin: true,             // freeze .wrap while the tween plays
    scrub: 1,              // tie progress to scrollbar (1 = 1s catch-up smoothing)
    markers: true,         // dev-only — remove for prod
  },
});
```

- `start`/`end`: `"triggerPos viewportPos"` (e.g. `"top center"`) or `"+=px"`.
- `scrub: true` locks progress to scroll; `scrub: <number>` adds smoothing lag.
- `toggleActions: "play pause resume reverse"` maps onEnter/onLeave/onEnterBack/onLeaveBack for non-scrubbed triggers.
- Scrubbed tweens use `ease: "none"`.
- Call `ScrollTrigger.refresh()` after viewport/content changes.

### Lenis smooth scroll + ScrollTrigger

Lenis smooths on its own rAF while ScrollTrigger reads scroll on GSAP's ticker; ticking independently, ScrollTrigger samples a stale position. Run both on one loop:

```js
import Lenis from "lenis";

const lenis = new Lenis({ duration: 1.2, smoothWheel: true });

lenis.on("scroll", ScrollTrigger.update);          // 1. update ScrollTrigger on every Lenis scroll
gsap.ticker.add((t) => lenis.raf(t * 1000));       // 2. ticker drives Lenis (seconds → ms)
gsap.ticker.lagSmoothing(0);                        // 3. stop catch-up jitter on heavy frames
```

`gsap.ticker` passes **seconds**, `lenis.raf()` wants **milliseconds**. Do not also run a standalone `requestAnimationFrame(raf)` loop — that double-drives Lenis. On SPA unmount: `gsap.ticker.remove(update)` + `lenis.destroy()`, else loops stack per navigation. Under reduced motion skip Lenis and use native scroll.

| Symptom | Cause / fix |
|---|---|
| Jitter/stutter | Leftover `requestAnimationFrame(raf)` loop, or missing `lagSmoothing(0)` |
| Markers drift from triggers | `ScrollTrigger.update` not subscribed to `lenis.on("scroll", …)` |
| Pins break | Lenis: do NOT set `scrollerProxy` (it scrolls the document). Locomotive: MUST wire `scrollerProxy` + `pinType` and set `scroller:` on every trigger |
| Scroll stuck / direction flipped | Missing `* 1000`, or two loops out of order |

### SplitText

```js
const split = SplitText.create(".headline", { type: "lines, words", linesClass: "line" });
gsap.from(split.lines, { yPercent: 100, opacity: 0, stagger: 0.08, duration: 0.7, ease: "power4.out" });
```

- `overflow: hidden` on the line wrapper so `yPercent: 100` hides cleanly. `autoSplit: true` (GSAP 3.13+) re-splits on font load / resize.
- `split.revert()` before re-splitting or on unmount, or nodes duplicate.
- Split after fonts load (`document.fonts.ready.then(...)`) or line breaks are wrong.

### Flip

Record state, change the DOM instantly, animate the difference:

```js
const state = Flip.getState(".item");   // 1. capture BEFORE
container.classList.toggle("grid");      // 2. mutate DOM/CSS (instant)
Flip.from(state, {                        // 3. animate the delta
  duration: 0.6, ease: "power2.inOut", stagger: 0.05,
  absolute: true,                         // out of flow during move (prevents reflow jitter)
});
```

### Performance and cleanup

- Animate `x/y/xPercent/scale/rotation` and `opacity`, not `top/left/width/height`. Frame budget and compositing: animation-performance.
- `will-change: transform` on heavy/pinned elements; remove after.
- Orphaned triggers leak memory and ghost-pin. Use `gsap.context()` or `useGSAP` from `@gsap/react`:

```js
useEffect(() => {
  const ctx = gsap.context(() => {
    // all gsap + ScrollTrigger code here
  }, rootRef);
  return () => ctx.revert(); // kills tweens, triggers, and reverts inline styles
}, []);
```

### Standalone deliverable

A self-contained hero, reveal, loop or micro-scene is one HTML file: GSAP + plugins from CDN, markup, and all motion on **one master timeline** in one inline `<script>`. `?t=N` seeks and pauses it for screenshots:

```html
<script>
  // ... build your master timeline as `tl` ...
  const t = new URLSearchParams(location.search).get("t");
  if (t !== null) { tl.pause(); tl.seek(parseFloat(t)); }  // frozen at t seconds
  window.__ready = true;
  console.log("duration", tl.duration());
</script>
```

```bash
bunx playwright screenshot --wait-for-timeout=500 "file://$PWD/anim.html?t=1.2" frame-mid.png
```

Screenshot `?t=0`, `?t=<dur/2>`, `?t=<dur>` (end from `tl.duration()`) and confirm: no console errors or missing CDN; matches the brief; no clipped text, off-canvas elements, FOUC before fonts, or seam jank; reduced motion simplifies or skips the timeline; no accidental `linear` on spatial motion. Template with the harness wired in: `examples/standalone-template.html`.

### References

- `references/scrolltrigger-cookbook.md` — read for pin, scrub, horizontal scroll, snap, `ScrollTrigger.batch()`, parallax, nested triggers, SPA cleanup.
- `references/scrolltrigger-lenis.md` — read for full Lenis/Locomotive wiring, `scrollerProxy`, anchor links, `data-lenis-prevent`, reduced motion, React (`useGSAP`/`useEffect`), debugging checklist.
- `examples/hero-timeline.js` — runnable hero entrance with SplitText, staggered reveals, reduced-motion handling.
- `examples/standalone-template.html` — CDN GSAP, one master timeline, `?t=N` harness, reduced-motion handling.

## Common Mistakes

| Mistake | Fix |
|---|---|
| Plugin not registered | `gsap.registerPlugin(...)` before use |
| Eased scrubbed tween | `ease: "none"` |
| `markers: true` shipped | Remove for prod |
| SplitText before fonts load | `document.fonts.ready.then(...)` |
| No cleanup in SPA | `gsap.context()` + `ctx.revert()` |
