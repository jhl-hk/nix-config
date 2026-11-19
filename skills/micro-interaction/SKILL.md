---
name: micro-interaction
description: Use when adding or fixing component-level UI feedback — hover/press/focus effects, toggles and switches, a like/heart button, toast or snackbar enter/exit, drawer/modal/tooltip/accordion open and close, list add/remove/reorder, shared-element layout transitions (layout, layoutId), loading → success → error states — with Framer Motion (motion/react) or CSS (@starting-style, transition-behavior: allow-discrete). Not for several elements sequenced together; use choreograph. Not for route changes; use page-transition-animation. Not for drag, swipe or sheet gestures; use apple-design.
version: 0.1.0
---

# Micro-interactions

## Overview

Small, functional motion on one component: feedback and continuity, not decoration.

## When to Use

- Hover/press/focus feedback; toggles, checkboxes, like buttons
- Toasts, drawers, modals, tooltips, accordions (enter/exit)
- List add/remove/reorder; shared-element ("magic move") layout transitions
- Loading → success → error state transitions

Choosing easing and duration from scratch: animate. Reduced-motion tiering: accessible-animation.

## Core Pattern

| Before | After |
|---|---|
| Animate `width/height/top/left` | `scale` or `layout` animation (`transform`/`opacity` only) |
| Toast exit holds its space | `AnimatePresence mode="popLayout"` |
| Spinner jump-cuts to checkmark | Keep the element mounted; morph spinner → checkmark |
| Conditional render with `exit` but no wrapper | Wrap in `AnimatePresence`, stable `key` |

## Quick Reference

| Need | Approach |
|------|----------|
| Press feedback | `whileTap={{ scale: 0.96 }}` spring 400/30 |
| Enter/exit | `AnimatePresence` + `initial/animate/exit` |
| Reorder / resize | `layout` prop (spring) |
| Magic move | shared `layoutId` |
| Toast stack | `AnimatePresence mode="popLayout"` |
| No-JS enter | `@starting-style` + transition |
| Animate to display:none | `transition-behavior: allow-discrete` |

Defaults:

- Duration **100–250ms**; over ~400ms feels laggy for a click response.
- Press feedback is instant: `scale: 0.96` with a fast spring.
- Enter slightly slower (ease-out), exit faster (ease-in).
- Easing: entrance `cubic-bezier(0.16, 1, 0.3, 1)`; tasteful overshoot `cubic-bezier(0.34, 1.56, 0.64, 1)`; standard move `cubic-bezier(0.4, 0, 0.2, 1)`.
- Reduced motion: keep opacity changes, drop large movement.

## Implementation

### Framer Motion (motion/react)

v11+ imports from `motion/react`; `framer-motion` still works.

```jsx
import { motion } from "motion/react";

<motion.button
  whileHover={{ scale: 1.03 }}
  whileTap={{ scale: 0.96 }}
  whileFocus={{ boxShadow: "0 0 0 3px rgba(59,130,246,.5)" }}
  transition={{ type: "spring", stiffness: 400, damping: 30 }}
/>
```

Higher `stiffness` = faster; higher `damping` = less bounce. `stiffness: 400, damping: 30` is a snappy UI default; `damping: 12` for visible bounce.

Exit animations need `AnimatePresence` around conditionally rendered children, each with a stable `key`:

```jsx
import { AnimatePresence, motion } from "motion/react";

<AnimatePresence>
  {open && (
    <motion.div
      key="panel"
      initial={{ opacity: 0, y: 8 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, y: 8 }}
      transition={{ duration: 0.2, ease: [0.16, 1, 0.3, 1] }}
    />
  )}
</AnimatePresence>
```

`layout` animates any position/size change with transforms — reordering, expanding cards, grid ↔ list:

```jsx
<motion.li layout transition={{ type: "spring", stiffness: 500, damping: 40 }} />
```

Two elements with the same `layoutId` animate as one when one mounts and the other unmounts:

```jsx
{!open && <motion.div layoutId="card" onClick={() => setOpen(true)} />}
<AnimatePresence>
  {open && <motion.div layoutId="card" />}
</AnimatePresence>
```

### CSS (no JS, including discrete properties)

```css
.toast {
  transition: opacity 0.2s ease, transform 0.2s ease;
  transition-behavior: allow-discrete; /* animate to/from display:none */
}
.toast[hidden] { display: none; }

@starting-style {
  .toast { opacity: 0; transform: translateY(8px); } /* values on first render / entering */
}
```

`@starting-style` sets the before-open values; `transition-behavior: allow-discrete` lets `display` (and `overlay` for popovers/dialogs) participate so exits run before removal. Baseline in Chrome/Edge/Safari; give older browsers a no-animation fallback.

### Standalone demo

A self-contained interaction demo is one HTML file that opens in a browser: pure CSS as-is, or React + `motion` from `esm.sh` in one inline module. No bundler.

A micro-interaction's frames are its states (idle / hover / pressed / open). `?state=open` applies the target state on load:

```html
<script>
  const s = new URLSearchParams(location.search).get("state");
  if (s) document.documentElement.dataset.state = s;   // CSS keys off [data-state="open"]
  // Framer Motion: set the controlled prop from `s` (e.g. const [open]=useState(s==="open"))
  // CSS @keyframes loop: el.style.animationDelay=(-N)+"s"; el.style.animationPlayState="paused";
  window.__ready = true;
</script>
```

```bash
bunx playwright screenshot --wait-for-timeout=400 "file://$PWD/demo.html?state=open" open.png
```

Before finishing, screenshot each state and confirm: no console errors and CDN resolves; `?state=` lands a settled state; press feedback reads instant and exits run before unmount; reduced motion drops movement but keeps feedback; durations in the 100–250ms band.

### References

- `references/framer-motion-recipes.md` — read for variants + stagger, `AnimatePresence` modes, `layout`/`layoutId`, `Reorder` drag-to-sort, drag constraints, gesture composition, `useReducedMotion`.
- `references/css-recipes.md` — read for `@starting-style`, `allow-discrete`, popover/dialog exits, keyframe spinners/toggles, `@property`, reduced-motion patterns.

## Common Mistakes

| Mistake | Fix |
|---|---|
| `layout` element distorts `border-radius` and text during scale | Add `layout` to direct children that should counter-scale; animate `borderRadius`/`boxShadow` as motion values; or `layout="position"` |
| Exit never runs | `AnimatePresence` wrapper + stable `key` |
| Toast holds space after exit | `mode="popLayout"` |
| Click response over ~400ms | Stay in 100–250ms |
| FOUC / jank in the demo | Check screenshots per state |
