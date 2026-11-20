---
name: svg-animation
description: Use when animating SVG — a line drawing itself on (stroke-dasharray / stroke-dashoffset, pathLength, signature animation), morphing one shape into another (MorphSVG, Flubber, animating d), moving an element along a path (MotionPath, offset-path, animateMotion), animated icons and logos (hamburger ↔ close, play ↔ pause), or animated SVG gradients and filters (feTurbulence, feDisplacementMap). Not for general GSAP timelines or ScrollTrigger; use gsap-web. Not for liquid-glass refraction surfaces; use glassmorphism. Not for non-SVG component feedback (hover, press, toggle, toast); use micro-interaction.
version: 0.1.0
---

# SVG Animation

## Overview

SVG animates three ways: CSS (declarative, simple), SMIL (`<animate*>` inside the SVG), and JS (GSAP / Web Animations, for control and morphing). Pick per task.

## When to Use

- Stroke draw-on of icons, illustrations, signatures, maps
- Path morphing and icon state changes (menu ↔ close, play ↔ pause)
- Moving an element along a path
- Animated gradients, filters (glow, displacement) and logos

## Core Pattern

| Before | After |
|---|---|
| Hard-coded dash length | `getTotalLength()` into `--len`, or `pathLength="1"` |
| Naive `d` morph between mismatched paths | MorphSVG or Flubber; or identical command structure |
| `<img src="icon.svg">` animated from CSS/JS | Inline the SVG |
| Draw-on on filled outlines | Real strokes: `fill:none; stroke:...` |

## Quick Reference

| Need | Use |
|------|-----|
| Single declarative draw/fade | CSS |
| Self-contained, no JS bundle | SMIL (`<animate*>` in the SVG) |
| Coordinated, scrubbable, scroll-tied | GSAP |
| Mismatched-point morph | GSAP MorphSVG or Flubber |
| Path following with rotation | GSAP MotionPath / CSS offset-path |

SMIL is unsupported in IE/old Edge and was historically deprecation-flagged; for max reach or scroll sync prefer CSS or JS. SMIL is fine for self-contained icon assets in evergreen browsers.

## Implementation

### Stroke draw-on

Dash array as long as the path, offset fully (invisible), animate offset to 0:

```css
.path {
  stroke-dasharray: var(--len);
  stroke-dashoffset: var(--len);
  animation: draw 1.4s var(--ease-in-out, cubic-bezier(0.77, 0, 0.175, 1)) forwards; /* curve tokens: animate */
}
@keyframes draw { to { stroke-dashoffset: 0; } }
```

- Length via JS (most reliable): `const len = path.getTotalLength(); path.style.setProperty("--len", len);`
- No JS: `pathLength="1"` on the `<path>`, then `stroke-dasharray: 1; stroke-dashoffset: 1;` animated to `0`.
- Erase: offset from 0 back to `len`. Stagger multiple paths with `animation-delay`.
- Drawing follows the path's point order; if it draws backwards, reverse the path in the editor or negate the offset sign.

### Morphing

Paths interpolate point by point, so a naive morph needs the **same number and type of commands** in both `d`.

GSAP MorphSVG handles mismatched point counts:

```js
gsap.registerPlugin(MorphSVGPlugin);
gsap.to("#start", { morphSVG: "#end", duration: 0.8, ease: "power2.inOut" });
// Convert any shape to a morph-able path:
MorphSVGPlugin.convertToPath("circle, rect, ellipse, line, polygon");
```

Flubber (small, no GSAP; good with React/Framer Motion):

```js
import { interpolate } from "flubber";
const interpolator = interpolate(pathA, pathB, { maxSegmentLength: 2 });
// interpolator(0) === pathA, interpolator(1) === pathB; feed t into a tween.
```

Hand-authored icon toggles: identical command structure, animate `d` directly via Web Animations or CSS (`d: path("...")` is animatable in modern browsers).

### Motion along a path

GSAP MotionPath (preferred: control, alignment, scrub):

```js
gsap.registerPlugin(MotionPathPlugin);
gsap.to("#rocket", {
  duration: 4, repeat: -1, ease: "none",
  motionPath: { path: "#track", align: "#track", autoRotate: true, alignOrigin: [0.5, 0.5] },
});
```

`autoRotate: true` follows the path tangent; `align` makes coordinates relative to the path.

SMIL:

```svg
<path id="track" d="M10,80 C40,10 120,10 150,80" fill="none"/>
<circle r="6" fill="#3b82f6">
  <animateMotion dur="3s" repeatCount="indefinite" rotate="auto">
    <mpath href="#track"/>
  </animateMotion>
</circle>
```

CSS: `offset-path: path("M10,80 C..."); animation: move 3s linear infinite;` with `@keyframes move { to { offset-distance: 100%; } }` and `offset-rotate: auto`.

### Gradients and filters

Animate `gradientTransform` or stop offsets. Sheen sweep:

```svg
<linearGradient id="sheen">
  <stop offset="0%"  stop-color="#fff" stop-opacity="0"/>
  <stop offset="50%" stop-color="#fff" stop-opacity=".8"/>
  <stop offset="100%" stop-color="#fff" stop-opacity="0"/>
  <animateTransform attributeName="gradientTransform" type="translate"
    from="-1 0" to="1 0" dur="2s" repeatCount="indefinite"/>
</linearGradient>
```

Filters: `feDisplacementMap` `scale` for gooey/wobble, `feGaussianBlur` `stdDeviation` for focus pulls, `feColorMatrix`/`feFlood` for glow. Filters are paint-heavy: re-rendering a primitive every frame is the jank source.

### Authoring

- **SVGO**: keep `viewBox`, drop editor metadata; disable `cleanupIds`/`removeViewBox` and any plugin renaming IDs referenced from CSS/JS/SMIL. Disable `mergePaths` and `convertShapeToPath` when animating individual sub-paths or shapes.
- Inline in the DOM; `<img>`-embedded SVG can only self-animate via internal SMIL/CSS.
- Explicit `viewBox`, no fixed `width`/`height`.
- Reduced motion: gate looping/large motion, keep a static final state.

### Standalone deliverable

One HTML file with the inline `<svg>` and one driver (CSS `@keyframes`, GSAP from CDN, or SMIL). Freeze frames with the harness in animate (`references/standalone-harness.md`); `?t=N` uses the mechanism matching the driver.

Screenshot start / mid / end and confirm: no console errors; stroke draws in the right direction, morph endpoints clean; no path clipped by `viewBox`, no stroke vanishing from a stale dashoffset, no seam jank; reduced motion honored; no accidental `linear` draw-on.

### References

- `references/svg-techniques.md` — read for dashoffset math and `getTotalLength` gotchas, `pathLength="1"`, MorphSVG vs Flubber guide, hamburger ↔ close morph, MotionPath/offset-path details, SMIL vs CSS vs JS tradeoffs, an SVGO config tuned for animation.

## Common Mistakes

| Mistake | Fix |
|---|---|
| Animated IDs broken after SVGO | Disable `cleanupIds` and ID-renaming plugins |
| Janky filter animation | Keep the filter static and animate `transform`/`opacity` on the filtered layer or its wrapper; animate a primitive (`scale`, `stdDeviation`) only on small elements, briefly |
