---
name: animate
description: Use when asked to animate something, add motion or a transition, make a component feel alive, or choose easing, duration, cubic-bezier, spring config, keyframes vs transitions, or CSS vs Framer Motion/Motion/WAAPI for a new animation. Not for reviewing, auditing or removing existing motion; use improve-animations. Not for several elements sequenced together; use choreograph. Not for hover/toggle/toast/modal feedback patterns; use micro-interaction. Not for route or page transitions; use page-transition-animation. Not for GSAP or ScrollTrigger; use gsap-web. Not for SVG line drawing or morphing; use svg-animation. Not for jank or dropped frames; use animation-performance. Not for drag/swipe gestures; use apple-design. Not for reduced-motion policy in depth; use accessible-animation.
---

# Animate

## Overview

Turn a request for motion into an implementation. Decide in order: should it animate, why, which tool, which properties, which curve/duration or spring, how it interrupts and exits. Sometimes the right output is zero lines of code.

## When to Use

- Building a new animation or transition.
- Picking easing, duration or spring values.

Make the call; never present motion options as a menu. State the reasoning in one line, then write the code.

## Core Pattern

| Wrong | Right |
|---|---|
| Animate a command-palette toggle | No animation (100+/day) |
| `transform: scale(0)` entrance | `scale(0.95)` + `opacity: 0` |
| `animation: fadeIn 400ms ease-in` | `transition: opacity 200ms var(--ease-out)` |
| Invented `cubic-bezier(0.4, 0, 0.2, 1)` | A curve from the tables below |
| New `--ease-*` set beside the codebase's | Reuse existing tokens |
| Install a motion library for a fade | CSS transition |

## Quick Reference

### Frequency

| Frequency | Decision |
|---|---|
| 100+ times/day (keyboard shortcuts, command palette) | No animation. Stop. |
| Tens of times/day (hover, list navigation) | Near-imperceptible or nothing |
| Occasional (modals, drawers, toasts) | Standard animation |
| Rare / first-time (onboarding, success) | Delight allowed |

### Tool — cheapest that works

| Need | Tool |
|---|---|
| Hover, press, color, class/attribute toggle | CSS transition |
| Entry on mount, no JS state | CSS `@starting-style` |
| Predetermined motion that must stay smooth while the page loads | CSS animation (off main thread) |
| Programmatic control, CSS performance, no library | WAAPI (`element.animate()`) |
| Springs, layout, exit, gesture-driven values | Motion (`motion.dev`) |

### Easing

| Situation | Easing |
|---|---|
| Entering or exiting | `ease-out` |
| Moving / morphing on screen | `ease-in-out` |
| Hover / color change | `ease` |
| Constant motion (marquee, ticker, hold-to-delete progress) | `linear` |
| Default | `ease-out` |

Built-in CSS easings are too weak. Defaults:

```css
--ease-out: cubic-bezier(0.23, 1, 0.32, 1);        /* strong ease-out for UI */
--ease-in-out: cubic-bezier(0.77, 0, 0.175, 1);    /* strong ease-in-out for on-screen movement */
--ease-drawer: cubic-bezier(0.32, 0.72, 0, 1);     /* iOS-like drawer curve (Ionic) */
--ease-overshoot: cubic-bezier(0.34, 1.56, 0.64, 1); /* tasteful overshoot for toggles and press release */
```

Other strengths, weak to strong:

| Family | ease-out | ease-in-out |
|---|---|---|
| quad | `cubic-bezier(0.25, 0.46, 0.45, 0.94)` | `cubic-bezier(0.455, 0.03, 0.515, 0.955)` |
| cubic | `cubic-bezier(0.215, 0.61, 0.355, 1)` | `cubic-bezier(0.645, 0.045, 0.355, 1)` |
| quart | `cubic-bezier(0.165, 0.84, 0.44, 1)` | `cubic-bezier(0.77, 0, 0.175, 1)` |
| quint | `cubic-bezier(0.23, 1, 0.32, 1)` | `cubic-bezier(0.86, 0, 0.07, 1)` |
| expo | `cubic-bezier(0.19, 1, 0.22, 1)` | `cubic-bezier(1, 0, 0, 1)` |
| circ | `cubic-bezier(0.075, 0.82, 0.165, 1)` | `cubic-bezier(0.785, 0.135, 0.15, 0.86)` |

Anything else: take it from [easing.dev](https://easing.dev/) or [easings.co](https://easings.co/), never hand-roll.

### Duration

| Element | Duration |
|---|---|
| Button press feedback | 100–160ms |
| Tooltips, small popovers | 125–200ms |
| Dropdowns, selects | 150–250ms |
| Modals, drawers | 200–500ms |
| Marketing / explanatory | Can be longer |

### Springs

```js
{ type: "spring", duration: 0.5, bounce: 0.2 }            // Apple-style, easier to reason about
{ type: "spring", mass: 1, stiffness: 100, damping: 10 }  // traditional physics, more control
```

Starting points: snappy UI `duration: 0.3, bounce: 0`; list reorder / layout `duration: 0.35, bounce: 0`; visible bounce `bounce: 0.25`.

Converting stiffness/damping to duration/bounce: keep the feel. Bounce ≈ 1 − damping ratio, where ratio = damping / (2·√(stiffness·mass)), clamped to [0, 1). Example: stiffness 100, damping 10, mass 1 → ratio 0.5 → `bounce: 0.5`. Exception: everyday UI (press feedback, list staggers) uses `bounce: 0` whatever the source; only drag and playful moments keep the converted bounce. Duration is set by feel (snappy UI 0.3, layout 0.35), not copied from the physical settle time.

## Implementation

Decide in order; stop when a step says no.

### 1. Should it animate?

Place the request in the Frequency table. Keyboard-initiated actions (arrow-key navigation, shortcuts, tab/focus moves) never animate. Raycast has no open/close animation. If the request fails this gate, say so and offer the non-motion alternative.

Marketing may be elaborate and longer; product motion is fast and purposeful.

### 2. Purpose

Name one before continuing; no name, no animation. "It looks cool" is not one.

- **Feedback** — the interface heard the user (press scale, hold-to-confirm fill)
- **Spatial consistency** — where something came from or went (toast enters and exits the same edge; panel grows from its trigger)
- **State indication** — a state change made legible (morphing button, expanding accordion)
- **Preventing a jarring change** — bridging content that would teleport, appear or vanish
- **Explanation** — demonstrates how a feature works; marketing/onboarding only
- **Delight** — rare/first-time tier only

Data the user reads or acts on does not move for style. Mouse-tracking decoration belongs on a marketing page, not a banking graph.

### 3. Tool

Take the cheapest row of the Tool table that works. `requestAnimationFrame`-based JS drops frames while the browser loads, scripts or paints. CSS for predetermined motion, JS for dynamic and interruptible motion.

### 4. Properties

- `transform` and `opacity` only; they skip layout and paint. `width`/`height`/`margin`/`padding`/`top`/`left` trigger layout. `clip-path` is the sanctioned fourth (see RECIPES.md); `height` only for accordions.
- Never `scale(0)`. Start from `scale(0.9–0.97)` + `opacity: 0`.
- `transform-origin` at the trigger for popovers, dropdowns, menus, tooltips (`var(--transform-origin)` in Base UI). Modals stay centered.
- `translate()` percentages are relative to the element's own size; `translateY(100%)` moves by its own height. Prefer over pixels.
- Never drive a child's transform from a CSS variable on the parent; it recalculates styles for every child.
- Motion hardware-accelerates independent transforms from 14.2:

```jsx
<motion.div animate={{ x: 100 }} />                          // motion 14.2+: hardware accelerated
<motion.div animate={{ transform: "translateX(100px)" }} />  // hardware accelerated in every version
```

### 5. Easing

Pick from the Easing table, using the tokens. Never `ease-in` on UI: it delays the moment the user is watching. `ease-out` at 200ms feels faster than `ease-in` at 200ms.

### 6. Duration

Pick from the Duration table.

- UI stays under 300ms; a 180ms dropdown feels more responsive than 400ms.
- Larger elements and longer travel take longer.
- Exits can be ~20% faster than entrances.
- Paired elements (modal + overlay, tooltip + arrow, drawer + backdrop) share easing and duration.

### 7. Springs

Use for drag with momentum, elements that should feel alive (Dynamic Island), interruptible/reversible gestures, decorative mouse-tracking. Bounce 0.1–0.3, and only for drag-to-dismiss and playful interactions; none in most UI.

### 8. Interruption and exit

- Transitions, not keyframes, for anything fired rapidly (toasts, toggles): transitions retarget from the current value, keyframes restart from zero.
- Springs for gestures: they carry velocity through an interruption.
- Exit the way it entered; a toast from the bottom leaves through the bottom.
- Asymmetric timing where the user decides: slow deliberate phase (hold-to-confirm: 2s linear), snappy response (release: 200ms ease-out).

### 9. Reduced motion and hover gating

Ship with the animation. Reduced motion means fewer and gentler, not zero: keep opacity/color that aids comprehension, drop movement. Details: accessible-animation.

```css
@media (prefers-reduced-motion: reduce) {
  .element { animation: fade 0.2s ease; } /* keep opacity/color, drop transform-based motion */
}

@media (hover: hover) and (pointer: fine) {
  .element:hover { transform: scale(1.05); } /* touch fires false hovers on tap */
}
```

```jsx
const reduce = useReducedMotion();
const closedX = reduce ? 0 : '-100%';
```

### Recipes and references

- Common components — button press, dropdown, tooltip (including instant neighbours), modal, drawer, toast, accordion, stagger, hold-to-confirm, tab indicator, scroll reveal, drag-to-dismiss, blur-masked crossfade, WAAPI: start from `RECIPES.md`.
- Symptom fixes — 1px shake, Radix origin variable, hover flicker, small tap targets, perceived speed: read `references/practical-tips.md`.
- Checking a standalone demo by screenshot — freezing a frame (`?t=N` for CSS keyframes, WAAPI, GSAP, SMIL), forcing a state (`?state=`, `?view=`/`?phase=`), capturing reduced motion: read `references/standalone-harness.md`.
- Component itself missing (toast, drawer, command menu, dropdown): use an accessible headless library (Base UI, Radix) rather than hand-rolling a `<div>` without focus management.

### Output

The code, then at most a few lines — frequency tier and purpose (and anything rejected, with why); tool, properties, curve, duration/spring, one line each; what to feel-check if feel can't be judged from code (play at 2–5× duration or in the DevTools animation inspector, step frame by frame, test gestures on a real device, look again the next day). No report.

## Common Mistakes

| Never | Instead |
|---|---|
| `transition: all` | Name the exact properties |
| Built-in `ease-out` on a deliberate animation | `cubic-bezier(0.23, 1, 0.32, 1)` |
| UI duration over 300ms without reason | 150–250ms |
| `transform-origin: center` on a trigger-anchored popover | `var(--transform-origin)` (modals exempt) |
| Keyframes on toasts, toggles, rapid triggers | CSS transitions |
| Animating `width`/`height`/`margin`/`padding`/`top`/`left` | `transform` / `opacity` |
| `blur` above 20px | Under 20px |
| Motion `x`/`y`/`scale` under load before 14.2 | Upgrade to 14.2+, or a full `transform` string |
| React state updated every frame | Refs / direct style writes outside the render cycle |
| Ungated `:hover` motion | `@media (hover: hover) and (pointer: fine)` |
| Missing `prefers-reduced-motion` | Gentler variant, not zero |
| Everything entering at once | 30–80ms stagger (see choreograph) |
| Shipping in one sitting | Re-check with fresh eyes the next day |
