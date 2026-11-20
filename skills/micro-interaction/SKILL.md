---
name: micro-interaction
description: Use when adding or fixing component-level UI feedback — hover/press/focus effects, toggles and switches, a like/heart button, toast or snackbar enter/exit, drawer/modal/tooltip/accordion open and close, list add/remove/reorder, shared-element layout transitions (layout, layoutId), loading → success → error states — with Framer Motion (motion/react) or CSS (@starting-style, transition-behavior: allow-discrete). Not for several elements sequenced together; use choreograph. Not for route changes; use page-transition-animation. Not for drag, swipe or sheet gestures; use apple-design. Not for choosing easing/duration; use animate.
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
| Press feedback | `whileTap={{ scale: 0.96 }}` spring `duration: 0.3, bounce: 0` |
| Enter/exit | `AnimatePresence` + `initial/animate/exit` |
| Reorder / resize | `layout` prop (spring) |
| Magic move | shared `layoutId` |
| Toast stack | `AnimatePresence mode="popLayout"` |
| No-JS enter | `@starting-style` + transition |
| Animate to display:none | `transition-behavior: allow-discrete` |

Defaults:

- Duration **100–250ms**; over 300ms feels laggy for a click response.
- Press feedback is instant: `scale: 0.96` with a fast spring.
- Enter slightly slower, exit ~20% faster; both ease-out (animate).
- Easing: animate's tokens — entrance `--ease-out`, toggle/press-release overshoot `--ease-overshoot`.
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
  transition={{ type: "spring", duration: 0.3, bounce: 0 }}
/>
```

Exit animations need `AnimatePresence` around conditionally rendered children, each with a stable `key`:

```jsx
import { AnimatePresence, motion } from "motion/react";

<AnimatePresence>
  {open && (
    <motion.div
      key="panel"
      initial={{ opacity: 0, y: 8 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, y: 8, transition: { duration: 0.16, ease: [0.23, 1, 0.32, 1] } }}
      transition={{ duration: 0.2, ease: [0.23, 1, 0.32, 1] }} /* animate's --ease-out */
    />
  )}
</AnimatePresence>
```

`layout` animates any position/size change with transforms — reordering, expanding cards, grid ↔ list:

```jsx
<motion.li layout transition={{ type: "spring", duration: 0.35, bounce: 0 }} />
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
  transition: opacity 0.2s var(--ease-out, cubic-bezier(0.23, 1, 0.32, 1)), transform 0.2s var(--ease-out, cubic-bezier(0.23, 1, 0.32, 1));
  transition-behavior: allow-discrete; /* animate to/from display:none */
}
.toast[hidden] { display: none; }

@starting-style {
  .toast { opacity: 0; transform: translateY(8px); } /* values on first render / entering */
}
```

`@starting-style` sets the before-open values; `transition-behavior: allow-discrete` lets `display` (and `overlay` for popovers/dialogs) participate so exits run before removal. Baseline in Chrome/Edge/Safari; give older browsers a no-animation fallback.

### Standalone demo

A self-contained interaction demo is one HTML file that opens in a browser: pure CSS as-is, or React + `motion` from `esm.sh` in one inline module. No bundler. Freeze frames with the harness in animate (`references/standalone-harness.md`).

A micro-interaction's frames are its states (idle / hover / pressed / open); force each with `?state=`.

Before finishing, screenshot each state and confirm: no console errors and CDN resolves; `?state=` lands a settled state; press feedback reads instant and exits run before unmount; reduced motion drops movement but keeps feedback; durations in the 100–250ms band.

### References

- `references/framer-motion-recipes.md` — read for variants + stagger, `AnimatePresence` modes, toast stack, `layout`/`layoutId`, `Reorder` drag-to-sort, drag constraints, gesture composition, performance notes.
- `references/css-recipes.md` — read for `@starting-style`, `allow-discrete`, popover/dialog exits, press/hover/focus feedback, keyframe spinners/toggles, `@property`, `interpolate-size` accordions.

## Common Mistakes

| Mistake | Fix |
|---|---|
| `layout` element distorts `border-radius` and text during scale | Add `layout` to direct children that should counter-scale; animate `borderRadius`/`boxShadow` as motion values; or `layout="position"` |
| Click response over 300ms | Stay in 100–250ms |
