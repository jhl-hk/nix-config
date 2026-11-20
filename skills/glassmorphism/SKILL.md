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

Full base-card CSS: `references/glass-recipes.md` §1.

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

Animate frost deepening, highlight brightening, the panel lifting. Hover is the tens-per-day tier: keep it ≤200ms and gate it to real pointers (curve tokens: animate).

```css
.glass {
  transition: backdrop-filter .2s ease, background .2s ease,
              box-shadow .2s ease, transform .2s var(--ease-out, cubic-bezier(0.23, 1, 0.32, 1));
}
@media (hover: hover) and (pointer: fine) {
  .glass:hover {
    backdrop-filter: blur(24px) saturate(180%);
    background: rgba(255,255,255,.18);
    transform: translateY(-4px);
    box-shadow: 0 16px 48px rgba(0,0,0,.3), inset 0 1px 0 rgba(255,255,255,.5);
  }
}
```

- **Entrance** (frost resolving from clear): a `[data-enter]` transition on `var(--ease-out)` with `@starting-style { backdrop-filter: blur(0); opacity: 0; transform: translateY(16px) }`.
- **Specular sweep**: skewed white gradient across the surface on hover or as a slow ambient loop; move it with `transform`, never `left`.
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
- Promote heavy glass (`transform: translateZ(0)` or `will-change: transform`); remove `will-change` after animating (left on, it wastes memory).
- Don't stack `backdrop-filter` elements: nested blur re-blurs the blur (quadratic cost).
- Blur radii >40px over large areas are the worst case; cap the blur radius and panel size.

### Accessibility

- `prefers-reduced-transparency: reduce` → solid opaque panel, no `backdrop-filter` (prefixed too), grain dropped.
- `prefers-reduced-motion: reduce` → no glass transitions; sweep and refraction stopped (`.liquid { filter: none }`).
- `@supports not (backdrop-filter: blur(1px))` → opaque-enough fallback background.
- Contrast over photos can drop below WCAG: put a semi-opaque scrim or darkening gradient *under* the text, optionally `text-shadow: 0 1px 2px rgba(0,0,0,.4)`, and verify ≥ 4.5:1 body / ≥ 3:1 large against the *brightest* backdrop region.

CSS for all three fallbacks: `references/glass-recipes.md` §7.

### Standalone deliverable

One HTML file: a busy backdrop (photo or gradient — without it the demo lies), glass markup, CSS (frost + edge + grain + shadows), any inline SVG filter. Glass verifies by *state* (rest / hover / enter) and *time* (sweep and refraction loop). Freeze frames with the harness in animate (`references/standalone-harness.md`): `?state=hover` with CSS keyed off `:root[data-state="hover"] .glass { /* hover values */ }`, and `?t=N` freezing the CSS sweep and the SVG refraction (SMIL clock) together. Screenshot `?state=hover` and a loop frame such as `?t=2`.

For the fallbacks, emulate the media feature (reduced transparency, reduced motion) or use the harness's `?reduce=1` class toggle that mirrors the media query, and screenshot.

Confirm:

- No console errors.
- Blur and bright edge visible, shadow floats it, no banding.
- Text ≥ 4.5:1 over the brightest backdrop.
- Freezes deterministic.
- Reduced transparency → solid panel; reduced motion → refraction/sweep stopped; `@supports` fallback present.
- Glass count limited, blur not animated on a janky path, refraction on one element.

### References

- `references/glass-recipes.md` — read for full recipes: base card tiers, masked specular ring, grain, hover/enter/scroll motion, specular sweep, liquid-glass filter tuning, fallback CSS (reduced transparency, reduced motion, `@supports`).

## Common Mistakes

| Mistake | Fix |
|---|---|
| Flat box | Backdrop is a plain color; add image/gradient |
| Refraction molten | `scale` ≤ 30 |
| Unreadable text over photo | Scrim under text, verify contrast |
