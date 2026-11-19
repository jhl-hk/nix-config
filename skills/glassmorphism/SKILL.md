---
name: glassmorphism
description: Use when building frosted or liquid glass UI — glassmorphism cards, frosted nav bars, sidebars, glass modals/dialogs and toolbars, Apple liquid glass style, translucent panels with backdrop-filter blur, refracting liquid-glass heroes (feDisplacementMap, feTurbulence), glass hover/enter/scroll motion, or prefers-reduced-transparency fallbacks. Not for general SVG filter animation; use svg-animation. Not for whole-site visual direction; use design-taste-frontend or impeccable.
version: 0.1.0
---

# Glassmorphism (Frosted & Liquid Glass)

## Overview

Glass is four properties together — frost, translucency, a lit edge, layered depth — or it reads as a plain translucent box. Liquid glass adds refraction (the background bends through the panel) and moving specular highlights.

## When to Use

- Frosted cards, nav bars, sidebars, modals, toolbars over busy/photo backgrounds
- Login/hero panels and overlays layered above the page
- Liquid-glass heroes: refracting, slowly churning surfaces with a specular sweep
- Hover/scroll/enter motion on glass

`backdrop-filter` only blurs what sits behind the element: over a flat color it does nothing visible. Glass needs a busy backdrop (image, gradient, video).

## Core Pattern

1. **Frost** — `backdrop-filter: blur()` plus `saturate()` to keep color vivid.
2. **Translucency** — `background` alpha ~0.08–0.18; never opaque, never clear.
3. **Edge** — hairline border *brighter* than the fill, ideally lit top-left → dim bottom-right.
4. **Depth** — layered `box-shadow`: ambient drop plus `inset` top highlight and bottom shade.

```css
.glass {
  background: rgba(255, 255, 255, 0.12);
  backdrop-filter: blur(16px) saturate(160%);
  -webkit-backdrop-filter: blur(16px) saturate(160%); /* Safari needs the prefix */
  border-radius: 20px;
  border: 1px solid rgba(255, 255, 255, 0.25);
  box-shadow:
    0 8px 32px rgba(0, 0, 0, 0.25),          /* float */
    inset 0 1px 0 rgba(255, 255, 255, 0.35), /* top highlight */
    inset 0 -1px 0 rgba(0, 0, 0, 0.12);      /* bottom shade */
}
```

| Tier | Blur | Alpha |
|---|---|---|
| Light UI chrome | `blur(8–12px)` | `0.08–0.14` |
| Heavy modal/login | `blur(24–40px)` | `0.10–0.18` |
| Dark glass | — | fill `rgba(0,0,0,0.3)`, softer top highlight |

## Quick Reference

| Need | Approach |
|------|----------|
| Base frost | `backdrop-filter: blur(16px) saturate(160%)` + alpha bg |
| Edge of glass | brighter `border` + masked `::before` lit-corner ring |
| Float / depth | `box-shadow` drop + `inset` top highlight & bottom shade |
| Kill banding | `feTurbulence` noise `::after`, `opacity ≤ .06` |
| Hover motion | transition `transform`/`box-shadow`/`background`, small blur delta |
| Entrance | `@starting-style { backdrop-filter: blur(0); opacity:0 }` |
| Liquid refraction | `feDisplacementMap` ← animated `feTurbulence`, via `filter` |
| Specular sweep | skewed white gradient animated across surface |
| Safari | always pair `-webkit-backdrop-filter` |
| Reduced transparency | solid opaque panel, drop grain |
| No backdrop-filter | `@supports not (...)` opaque-enough fallback |

## Implementation

### Specular edge and grain

Draw a masked 1px ring with a lit corner via `::before`; dither gradient banding (stepped contours under heavy blur) with faint `feTurbulence` noise via `::after` at `opacity ≤ 0.06`. Recipes in `references/glass-recipes.md`.

### Motion: animate the glass, not the geometry

Animate frost deepening, highlight brightening, the panel lifting:

```css
.glass {
  transition: backdrop-filter .4s ease, background .4s ease,
              box-shadow .4s ease, transform .4s cubic-bezier(.16,1,.3,1);
}
.glass:hover {
  backdrop-filter: blur(24px) saturate(180%);
  background: rgba(255,255,255,.18);
  transform: translateY(-4px);
  box-shadow: 0 16px 48px rgba(0,0,0,.3), inset 0 1px 0 rgba(255,255,255,.5);
}
```

- **Entrance** (frost resolving from clear): a `[data-enter]` transition with `@starting-style { backdrop-filter: blur(0); opacity: 0; transform: translateY(16px) }`.
- **Specular sweep**: skewed white gradient across the surface on hover or as a slow ambient loop.
- Animating blur *radius* re-blurs the backdrop every frame. If hover janks, animate `transform`/`box-shadow`/`background` and keep the blur delta small or snap it.

### Liquid glass (SVG refraction)

`feDisplacementMap` driven by animated `feTurbulence`, applied via `filter` (distorts the element's own pixels), layered over a `backdrop-filter` frost:

```html
<svg width="0" height="0" style="position:absolute"><filter id="liquid-glass">
  <feTurbulence type="fractalNoise" baseFrequency="0.008 0.012" numOctaves="2" seed="3" result="n">
    <animate attributeName="baseFrequency" dur="18s"
             values="0.008 0.012;0.012 0.008;0.008 0.012" repeatCount="indefinite"/>
  </feTurbulence>
  <feDisplacementMap in="SourceGraphic" in2="n" scale="22" xChannelSelector="R" yChannelSelector="G"/>
</filter></svg>
```

| Knob | Values |
|---|---|
| `scale` (refraction) | 8–14 subtle, 20–30 pronounced, >40 molten |
| `baseFrequency` | lower = larger, slower, more liquid waves |
| `animate dur` | 12–20s so it breathes |

Heavy: use on **one** hero element, not a grid.

### Performance

- Each glass element re-samples and blurs everything behind it; a dozen on screen tanks scroll FPS. Limit the count.
- Promote heavy glass (`transform: translateZ(0)` or `will-change: transform`); remove `will-change` after animating.
- Don't stack `backdrop-filter` elements: nested blur re-blurs the blur (quadratic cost).
- Radii >40px over large areas are worst case; cap radius and panel size.

### Accessibility

```css
@media (prefers-reduced-transparency: reduce) {
  .glass { background: #1a1a2e; backdrop-filter: none; -webkit-backdrop-filter: none; }
  .glass::after { display: none; }            /* drop grain */
}
@media (prefers-reduced-motion: reduce) {
  .glass { transition: none; }
  .liquid { filter: none; }                   /* stop the refraction churn */
}
@supports not (backdrop-filter: blur(1px)) {
  .glass { background: rgba(30,30,50,.85); }  /* opaque-enough fallback */
}
```

Contrast over photos can drop below WCAG: put a semi-opaque scrim or darkening gradient *under* the text, optionally `text-shadow: 0 1px 2px rgba(0,0,0,.4)`, and verify ≥ 4.5:1 body / ≥ 3:1 large against the *brightest* backdrop region.

### Standalone deliverable

One HTML file: a busy backdrop (photo or gradient — without it the demo lies), glass markup, CSS (frost + edge + grain + shadows), any inline SVG filter. `?state=hover` forces a state; `?t=N` freezes CSS animations and the refraction:

```html
<script>
  const p = new URLSearchParams(location.search);
  const state = p.get("state");
  if (state) document.documentElement.dataset.state = state;   // CSS keys off :root[data-state="hover"]
  const t = p.get("t");
  if (t !== null) {
    document.getAnimations().forEach(a => { a.currentTime = parseFloat(t)*1000; a.pause(); }); // freeze CSS sweep
    const svg = document.querySelector("svg");
    svg?.pauseAnimations?.(); svg?.setCurrentTime?.(parseFloat(t));                            // freeze refraction
  }
  window.__ready = true;
</script>
```

```bash
bunx playwright screenshot --wait-for-timeout=500 "file://$PWD/glass.html?state=hover" hover.png
bunx playwright screenshot --wait-for-timeout=500 "file://$PWD/glass.html?t=2"          loop.png
```

For the fallback, emulate the media feature or add a `?reduced=1` query toggling a class that mirrors the media query, and screenshot.

Confirm: no console errors; blur and bright edge visible, shadow floats it, no banding; text ≥ 4.5:1 over the brightest backdrop; freezes deterministic; reduced transparency → solid panel, reduced motion → refraction/sweep stopped, `@supports` fallback present; glass count limited, blur not animated on a janky path, refraction on one element.

### References

- `references/glass-recipes.md` — read for full recipes: base card tiers, masked specular ring, grain, hover/enter/scroll motion, specular sweep, liquid-glass filter tuning, performance rules, fallbacks, contrast defenses, freeze harness.

## Common Mistakes

| Mistake | Fix |
|---|---|
| Flat box | Backdrop is a plain color; add image/gradient |
| No blur in Safari | Add `-webkit-backdrop-filter` |
| Refraction molten | `scale` ≤ 30 |
| Hover jank | Don't animate blur radius; animate transform/shadow/background |
| Stacked glass panels | Never nest `backdrop-filter` |
| Unreadable text over photo | Scrim under text, verify contrast |
