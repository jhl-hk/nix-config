---
name: animation-performance
description: Use when a web animation is janky, choppy, stutters or drops frames; when a hover or scroll effect feels heavy; when animating width, height, top, left, margin, box-shadow, blur or height auto; when converting an animation to transform, using FLIP, or fixing layout thrashing; when deciding CSS vs WAAPI vs requestAnimationFrame vs Motion on performance grounds; or when reaching for `will-change` or GPU layers. Not for easing, duration or whether to animate; use animate. Not for auditing a codebase's motion; use improve-animations. Not for reduced motion; use accessible-animation.
---

# Animation Performance

## Overview

Each frame must finish inside the budget: **16.7ms** at 60Hz, **8ms** at 120Hz (most phones, many laptops). Design against 8ms. Two things decide it: **what you animate** (cost per frame) and **where it runs** (whether busy JavaScript can block it).

## When to Use

- Motion stutters, drops frames, or degrades as content grows.
- Choosing which property to animate, or a cheaper equivalent.
- Animating a layout change (reorder, resize, move between containers) or `height: auto`.
- Jank only during navigation, fetching or hydration.

## Core Pattern

```css
/* Layout every frame */
.box { transition: left 300ms, width 300ms; left: 0; width: 100px; }
.box:hover { left: 200px; width: 200px; }

/* Compositor only */
.box {
  transition: transform 300ms ease;
  transform: translateX(0) scaleX(1);
  transform-origin: left center;
}
.box:hover { transform: translateX(200px) scaleX(2); }
```

`scaleX` stretches text and children. For true resizing without distortion, use FLIP.

Rules:

1. **`transform` and `opacity` by default.** Anything else needs a reason, even when the expensive property "seems fine".
2. **Name the cause before changing code.** Every fix names which cause in the diagnosis list it addresses.
3. **A fast laptop proves nothing.** The bar is a mid-range phone. State which findings are verified from code and which need a device recording.
4. **Never `transition: all`.** List exact properties; `all` animates whatever changes next, including layout.
5. **`will-change` is the last step.** Most jank is the wrong property or a busy main thread; it fixes neither.

## Quick Reference

### Property tiers

| Tier | Properties | Cost |
|---|---|---|
| Composite only | `transform`, `opacity`; in current Chrome/Firefox also `filter`, `clip-path`, `background-color` | Cheapest; promoted to own layer. Test the non-`transform`/`opacity` ones across browsers. |
| Paint + composite | `box-shadow`, `border-radius`, `color`, `background-position` | Redraw every frame |
| Layout + paint + composite | `width`, `height`, `padding`, `margin`, `top`, `left`, `right`, `bottom`, `border-width` | Most expensive; moves neighbours too |

A layout recalculation on a complex page can exceed 100ms: a dozen missed frames.

### Swaps

| Instead of | Animate |
|---|---|
| `width` / `height` / `padding` | `scale()`; FLIP for true size |
| `top` / `left` / `margin` | `translate()` (percentages are relative to the element's own box, unlike `left: %`) |
| `display` / `visibility` | `opacity` |
| `box-shadow` | `filter: drop-shadow(…)`, or `opacity` of a `::after` holding the shadow |
| `filter: blur()` radius | cross-fade two layers via `opacity` |
| `background-position` | `translate()` on a child layer |
| `height: auto` | grid `0fr → 1fr`, or `interpolate-size: allow-keywords` |

A `padding` animation may look free on a simple element, but `scale()` looks the same and cannot regress on a slower device. Animating a sidebar's `margin-left` re-lays out the content beside it every frame; `translateX` does not.

### Drivers

| Driver | Thread |
|---|---|
| JS + `requestAnimationFrame` (GSAP, Motion layout animations) | Main thread, always |
| WAAPI (`element.animate()`, Motion `animate()`, `motion/react` components) | Can be hardware-accelerated |
| CSS transitions and keyframes | Can be hardware-accelerated |

Reliably accelerated: `transform`, `opacity`. Gaining support: `filter`, `clip-path`, `background-color`. A JS library that hands off to WAAPI can be accelerated; a rAF loop cannot.

## Implementation

### Busy main thread

Watch motion that plays alongside heavy work: page transitions, tab indicators during navigation, anything during fetching or hydration (see Real-World Impact).

Motion hands `opacity`, `transform`, `clip-path`, `filter` to WAAPI. Before motion 14.2 the `x`/`y`/`scale` shorthands run on the main thread; a full `transform` string is accelerated in every version (snippet: animate SKILL.md › Implementation › 4. Properties).

Always main thread: `layout`, `layoutId`, `onUpdate`, `transformTemplate`, inertia, values driven per frame by a motion value (drag, `useTransform`).

Acceleration is progressive enhancement; browsers decline it silently (Chrome historically skipped percentage transforms). Keep `translateY(100%)` for elements of unknown size (Sonner, Vaul) — correctness beats a best-effort optimization.

JS animation is fine when the page is idle. Split: CSS for simple motion and anything that plays while the page is busy; Framer Motion for springs, shared layout, exit animations, momentum gestures.

### React: don't animate through state

```jsx
setY(nextY);                                               // re-render per frame: drops frames
ref.current.style.transform = `translateY(${nextY}px)`;    // no re-render
// or a motion value: y.set(nextY)
```

Look for state updates inside `requestAnimationFrame`, `pointermove`, `scroll`, or drag handlers. Animation libraries already run outside React's render cycle.

### Traps that use `transform` and still drop frames

**Inherited CSS variables.** Vaul's drag lagged past ~20 items:

```js
const style = { "--swipe-amount": `${draggedDistance}px` };       // restyles every descendant per frame
const style = { transform: `translateY(${draggedDistance}px)` };  // this element only
```

Suspect this whenever a `transform` animation degrades as content grows.

**Blur.** `filter: blur()` and `backdrop-filter` are expensive, especially in Safari. Keep animated blur under 20px; 2–5px softens a crossfade.

### Shadow via pseudo-element

```css
.card { position: relative; }
.card::after {
  content: "";
  position: absolute;
  inset: 0;
  border-radius: inherit;
  box-shadow: 0 12px 28px rgba(0,0,0,0.35);
  opacity: 0;
  transition: opacity 300ms ease;
  pointer-events: none;
}
.card:hover::after { opacity: 1; }
```

### FLIP

Measure First, mutate, measure Last, Invert with a transform, Play back to identity. The DOM ends in its real layout; motion is compositor work.

```js
function flip(el, mutate) {
  const first = el.getBoundingClientRect();
  mutate();
  const last = el.getBoundingClientRect();
  const dx = first.left - last.left;
  const dy = first.top - last.top;
  const sx = first.width / last.width;
  const sy = first.height / last.height;
  el.animate(
    [
      { transformOrigin: 'top left', transform: `translate(${dx}px, ${dy}px) scale(${sx}, ${sy})` },
      { transformOrigin: 'top left', transform: 'none' },
    ],
    { duration: 300, easing: 'cubic-bezier(0.23, 1, 0.32, 1)' } // animate's --ease-out
  );
}

flip(card, () => targetContainer.appendChild(card));
```

For many elements, read every rect before any mutation (reorder example in the reference file).

### `height: auto`

```css
/* Chrome 129+ */
.panel {
  interpolate-size: allow-keywords;   /* or height: calc-size(auto, size) */
  height: 0;
  overflow: clip;
  transition: height 200ms var(--ease-out, cubic-bezier(0.23, 1, 0.32, 1)); /* animate's accordion duration and token */
}
.panel.open { height: auto; }

/* Cross-browser default */
.wrapper { display: grid; grid-template-rows: 0fr; transition: grid-template-rows 200ms var(--ease-out, cubic-bezier(0.23, 1, 0.32, 1)); }
.wrapper.open { grid-template-rows: 1fr; }
.wrapper > .content { overflow: hidden; min-height: 0; }  /* required or it won't collapse */
```

### Layout thrashing

Reading `offsetWidth`, `getBoundingClientRect`, `scrollTop` or `getComputedStyle` after a write forces a synchronous reflow.

```js
// Reflow every iteration
items.forEach((el) => {
  const w = el.offsetWidth;
  el.style.width = w * 1.5 + 'px';
});

// All reads, then all writes
const widths = items.map((el) => el.offsetWidth);
items.forEach((el, i) => { el.style.width = widths[i] * 1.5 + 'px'; });
```

For frame-synced work, read and write inside one `requestAnimationFrame` callback; fastdom formalizes the scheduling.

### `will-change`

A mid-flight CPU→GPU hand-off can shift the element by a pixel at start or end. `will-change: transform` promotes it up front.

- Add only after seeing the shift or measuring dropped frames; browsers already promote elements animating `transform`/`opacity`.
- Every layer costs GPU memory. Put it on the animating element, never `*`, large containers or many nodes.
- Prefer applying on intent and removing with `will-change: auto` when idle (snippet in the reference file).
- Earns its place on an expensive paint, like a large blurred element; keep the layer small.
- Prefer it over the `translateZ(0)` hack, which is harder to undo.

### Diagnosis workflow

1. **Inventory** every animation in scope; expand `transition: all` and Motion shorthands into real properties.

   | Element | Driver | Properties | Plays during |
   |---|---|---|---|
   | Tab indicator | `motion/react` `layoutId` | layout | route change |
   | Card hover | CSS transition | `all` | hover |

2. **Diagnose**, in order of likelihood:
   1. Non-`transform`/`opacity` properties: layout first, then `box-shadow` and `border-radius` → Swaps table.
   2. Jank coincides with navigation, fetching, hydration or a long task → CSS or WAAPI (off the main thread).
   3. React re-rendering per frame → write to `ref.current.style` or a motion value.
   4. Worse as content grows → inherited CSS variable (set `transform` on the element directly), or too many nodes animating.
   5. Animated CSS variable, or Motion `x`/`y`/`scale` before 14.2 → upgrade to `motion` 14.2+, or animate the full `transform` string.
   6. Animated `blur()` above 20px (lags most in Safari) → keep it under 20px, or cross-fade two layers.
   7. Interleaved layout reads and writes (many elements measured per frame) → batch reads, then writes.
   8. Element shifts 1px when motion starts or ends → `will-change: transform` on the animating element, only once you see it.
3. **Confirm with a recording**, not by feel: Performance panel shows no per-frame purple Layout or green Paint, only Composite Layers. Profile on a real mid-range phone over remote debugging; desktop CPU throttling does not model a weak GPU or small memory. Read `references/patterns-and-profiling.md` for the Rendering-tab walkthrough, headless screenshot checks, and runnable accordion, reorder and parallax examples; the CDP trace check is in animate's `references/standalone-harness.md`.
4. **Report** each finding, ordered by cost (layout before paint, busy main thread before idle), then stop. Apply fixes when asked.

   ```
   **[Element]**: `file.tsx:42`
   Cause: [which cause above]
   Before: `transition: all 200ms` (animates `padding`, triggers layout)
   After: `transition: transform 200ms` with `scale(0.97)`
   Verified: from code / needs a device recording
   ```

## Common Mistakes

| Mistake | Fix |
|---|---|
| Scroll handler reads layout per element | One `scrollY` read per rAF, `{ passive: true }` listener |

## Real-World Impact

Vercel's dashboard tab indicator used a Framer Motion shared layout animation, dropped frames while the next page loaded, and was fixed by moving it to CSS.
