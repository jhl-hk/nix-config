# Materials, depth and accessibility signals

Read when laying out translucent chrome, stacked sheets or text on translucency, or when wiring reduced-motion, reduced-transparency and contrast preferences into gesture UI. Glass surface CSS: glassmorphism. Reduced-motion tiers and WCAG: accessible-animation.

## Materials and depth

- Nav, toolbars and sheets as translucent layers (`backdrop-filter: blur()` + semi-transparent background) with content scrolling underneath.
- Heavier/darker materials separate structure (sidebars); lighter ones mark interactive elements. Never stack light translucent on light translucent.
- Larger surfaces read thicker: stronger blur, deeper shadow. Heavier shadow over busy content, lighter over plain.
- Modal task: dimming scrim, background pushed back. Parallel panel: translucency and offset, no scrim. Stacked sheets: dim and push back each parent.
- Text over translucency: higher contrast, slightly heavier weight, small letter-spacing bump, no flat gray. Color goes on a solid layer.
- Sticky header: fade a blur/gradient mask where content meets floating chrome instead of a 1px divider, only where they overlap.
- Glass enter/exit animates blur radius and scale together, not opacity alone.

```css
.toolbar {
  background: rgba(255, 255, 255, 0.6);
  backdrop-filter: blur(20px) saturate(180%);
  border-top: 1px solid rgba(255, 255, 255, 0.4);
}
```

## Accessibility signals

| Signal | Response |
|---|---|
| `prefers-reduced-motion: reduce` | Short opacity cross-fades instead of slides/springs/parallax; no overshoot; keep comprehension-aiding opacity/color |
| `prefers-reduced-transparency: reduce` | Raise background opacity, drop blur |
| `prefers-contrast: more` | Near-solid backgrounds, contrasting border |

Also avoid full-viewport moving backgrounds, slow loops near 0.2 Hz (one cycle per 5s) and abrupt brightness jumps (ease theme changes). Make large moving objects semi-transparent in transit; fade big surfaces out during large repositions.

```css
@media (prefers-reduced-motion: reduce) {
  .sheet { transition: opacity 200ms ease; transform: none !important; }
}
@media (prefers-reduced-transparency: reduce) {
  .toolbar { background: white; backdrop-filter: none; }
}
```
