# Glassmorphism Recipes

Frosted panels, the edge-of-glass highlight, animated liquid-glass refraction and the fallbacks. Standalone CSS plus optional inline SVG; no build step. Curve tokens (`--ease-out`, `--ease-in-out`) are defined in animate.

## 1. The base glass card

The four ingredients of believable glass: **blur** (frost), **translucency** (you see through it), **edge highlight** (light catches the rim), **layered shadow** (it floats). Plus a touch of `saturate()` so the backdrop reads vivid through the frost.

```css
.glass {
  /* translucency — never fully opaque, never fully clear */
  background: rgba(255, 255, 255, 0.12);
  /* frost: blur the backdrop, lift saturation so color survives the blur */
  backdrop-filter: blur(16px) saturate(160%);
  -webkit-backdrop-filter: blur(16px) saturate(160%); /* Safari still needs the prefix */
  border-radius: 20px;
  /* edge of glass: a hairline border slightly brighter than the fill */
  border: 1px solid rgba(255, 255, 255, 0.25);
  /* depth: ambient drop + a top inner highlight + a bottom inner shade */
  box-shadow:
    0 8px 32px rgba(0, 0, 0, 0.25),
    inset 0 1px 0 rgba(255, 255, 255, 0.35),
    inset 0 -1px 0 rgba(0, 0, 0, 0.12);
}
```

Tuning by tier:
- **Light frost** (UI chrome over content): `blur(8–12px)`, alpha `0.08–0.14`.
- **Heavy frost** (modal scrim, login card): `blur(24–40px)`, alpha `0.10–0.18`.
- Dark glass: swap the fill to `rgba(0,0,0,0.3)` and the top inner highlight to a softer white.

`backdrop-filter` only has anything to blur if there is content **behind** the element — it must overlap a busy background (image, gradient, video). On a flat color it looks like a plain translucent box.

## 2. The specular edge highlight (the rim of light)

A single border is flat. Real glass catches a bright sweep along the top-left edge and falls off. Layer a soft conic/linear highlight via a pseudo-element with a masked border.

```css
.glass {
  position: relative;
  isolation: isolate; /* keep the highlight blend local */
}
.glass::before {
  content: "";
  position: absolute;
  inset: 0;
  border-radius: inherit;
  padding: 1px;                       /* border thickness */
  background: linear-gradient(
    135deg,
    rgba(255, 255, 255, 0.7),
    rgba(255, 255, 255, 0) 40%,
    rgba(255, 255, 255, 0) 60%,
    rgba(255, 255, 255, 0.25)
  );
  /* mask trick: show only the 1px ring, punch out the interior */
  -webkit-mask:
    linear-gradient(#000 0 0) content-box,
    linear-gradient(#000 0 0);
  -webkit-mask-composite: xor;
          mask-composite: exclude;
  pointer-events: none;
}
```

This gives the panel a lit top-left corner and a dim bottom-right, the cue the brain reads as "curved glass under a light."

## 3. Kill banding with grain

Heavy `blur()` over a smooth gradient produces visible color **banding** (stepped contour lines). A faint noise overlay dithers it away.

```css
.glass::after {
  content: "";
  position: absolute;
  inset: 0;
  border-radius: inherit;
  pointer-events: none;
  opacity: 0.04;                       /* barely there */
  mix-blend-mode: overlay;
  background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='120' height='120'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='2'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)'/%3E%3C/svg%3E");
}
```

`feTurbulence` generates the noise tile inline — no asset file. Keep opacity ≤ 0.06 or it reads as texture, not dither.

## 4. Motion: animate the glass on hover / enter / scroll

Animate the *qualities* of the glass, not its geometry. Frost deepening and the highlight brightening on hover reads as the panel "leaning into the light." Hover is high-frequency: ≤200ms, gated to real pointers.

```css
.glass {
  transition:
    backdrop-filter 0.2s ease,
    background 0.2s ease,
    box-shadow 0.2s ease,
    transform 0.2s var(--ease-out, cubic-bezier(0.23, 1, 0.32, 1));
}
@media (hover: hover) and (pointer: fine) {
  .glass:hover {
    backdrop-filter: blur(24px) saturate(180%);
    background: rgba(255, 255, 255, 0.18);
    transform: translateY(-4px);
    box-shadow:
      0 16px 48px rgba(0, 0, 0, 0.3),
      inset 0 1px 0 rgba(255, 255, 255, 0.5);
  }
}
```

Caveat: animating `backdrop-filter` itself is the most expensive thing here — the backdrop is re-sampled and re-blurred every frame. If hover feels janky, animate only `transform` + `box-shadow` + `background` (cheaper) and snap the blur, or keep the blur change small.

**Entrance** (frost resolving in) reads beautifully with `@starting-style`:

```css
.glass[data-enter] {
  transition: opacity 0.5s var(--ease-out, cubic-bezier(0.23, 1, 0.32, 1)), backdrop-filter 0.6s var(--ease-out, cubic-bezier(0.23, 1, 0.32, 1)), transform 0.5s var(--ease-out, cubic-bezier(0.23, 1, 0.32, 1));
}
@starting-style {
  .glass[data-enter] {
    opacity: 0;
    backdrop-filter: blur(0px) saturate(100%);
    transform: translateY(16px) scale(0.98);
  }
}
```

**Specular sweep** — a moving glint across the surface on hover or as an ambient loop:

```css
.glass .sweep {
  position: absolute; inset: 0; border-radius: inherit; overflow: hidden; pointer-events: none;
}
.glass .sweep::before {
  content: ""; position: absolute; top: 0; left: -60%; width: 50%; height: 100%;
  background: linear-gradient(105deg, transparent, rgba(255,255,255,0.35), transparent);
  transform: translateX(0) skewX(-15deg);
  animation: sweep 4s var(--ease-in-out, cubic-bezier(0.77, 0, 0.175, 1)) infinite;
}
/* translateX % is of the glint's own width (50%): 340% = the old left: -60% → 110% travel */
@keyframes sweep {
  0%, 100% { transform: translateX(0) skewX(-15deg); }
  50%      { transform: translateX(340%) skewX(-15deg); }
}
```

Moving it with `left` would trigger layout every frame; `transform` stays on the compositor.

## 5. Liquid glass — SVG refraction

Apple-style "liquid glass" bends the background as if seen through a thick, wobbling lens. Drive a `feDisplacementMap` from animated `feTurbulence` and apply it via `filter` (note: `filter`, not `backdrop-filter` — it distorts the element's own rendered content; layer it over a `backdrop-filter` frost for the full effect).

```html
<svg width="0" height="0" style="position:absolute">
  <filter id="liquid-glass">
    <feTurbulence type="fractalNoise" baseFrequency="0.008 0.012"
                  numOctaves="2" seed="3" result="noise">
      <!-- animate the field so the refraction slowly churns -->
      <animate attributeName="baseFrequency"
               dur="18s" values="0.008 0.012; 0.012 0.008; 0.008 0.012"
               repeatCount="indefinite"/>
    </feTurbulence>
    <feDisplacementMap in="SourceGraphic" in2="noise"
                       scale="22" xChannelSelector="R" yChannelSelector="G"/>
  </filter>
</svg>
```

```css
.liquid {
  backdrop-filter: blur(6px) saturate(150%); /* light frost under the refraction */
  filter: url(#liquid-glass);                 /* the lens distortion */
}
```

Knobs:
- `scale` on `feDisplacementMap` = refraction strength. 8–14 = subtle ripple; 20–30 = pronounced lens; >40 = molten.
- Lower `baseFrequency` = larger, slower waves (more "liquid"); higher = tight, busy ripples.
- Animate `baseFrequency` (above) or `scale` for a living surface. Keep `dur` long (12–20s) so it breathes rather than shimmers.

Cost warning: SVG displacement filters are heavy and force off-GPU paths in some browsers. Use on **one** hero element, not a grid of cards. Test on a mid-range laptop; drop to plain `backdrop-filter` if frames stutter.

## 6. Performance — backdrop-filter is expensive

Rules (count limit, layer promotion, no stacked blur, radius cap, animate `transform`/`opacity`/`box-shadow` over blur radius): SKILL.md › Performance.

## 7. Accessibility — non-negotiable

Glass is decorative; the content on it must stay legible and the effect must be defeatable.

**Honor reduced transparency and reduced motion** — fall back to a solid, opaque panel:

```css
@media (prefers-reduced-transparency: reduce) {
  .glass {
    background: #1a1a2e;            /* solid, accessible panel */
    backdrop-filter: none;
    -webkit-backdrop-filter: none;
    border-color: rgba(255, 255, 255, 0.15);
  }
  .glass::after { display: none; }  /* drop grain/noise */
}

@media (prefers-reduced-motion: reduce) {
  .glass, .glass .sweep::before { transition: none; animation: none; }
  .liquid { filter: none; }         /* stop the churning refraction */
}
```

**Contrast over busy backgrounds:** SKILL.md › Accessibility.

**Feature fallback** for browsers without `backdrop-filter`:

```css
@supports not (backdrop-filter: blur(1px)) {
  .glass { background: rgba(30, 30, 50, 0.85); } /* opaque-enough fallback */
}
```

## 8. Standalone freeze harness

State and time targets, the `:root[data-state="hover"]` hook and the confirm list: SKILL.md › Standalone deliverable.
