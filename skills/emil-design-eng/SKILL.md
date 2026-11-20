---
name: emil-design-eng
description: Use when polishing a UI component or reviewing UI code for feel — buttons, popovers, tooltips, toasts, drawers, tabs; choosing between CSS transitions, keyframes, springs, clip-path, @starting-style or WAAPI for a component; or when an interface "works but doesn't feel right". Not for building one animation from scratch (use animate), multi-element sequencing (use choreograph), drag/swipe gesture physics (use apple-design), jank (use animation-performance), a full design audit of a product (use impeccable), or worst-case data (use break-ui).
---

# Design Engineering

## Overview

Invisible details compound: when every interaction behaves exactly as the user assumes, the interface feels right without anyone knowing why. Good defaults and good motion are product differentiators, not decoration.

## When to Use

- Building or refining a component's interaction details (press, open/close, hover, enter/exit).
- Reviewing UI code for polish; output the review in the format below.
- Picking values (easing, duration, origin, scale) for component motion.

Not for: a whole-product design critique (impeccable), marketing sites (design-taste-frontend), reduced-motion policy (accessible-animation), native-feel fixes on phones (mobile-native).

## Review Format

One markdown table, one row per issue. Never a list of `Before:` / `After:` lines.

| Before | After | Why |
| --- | --- | --- |
| `transition: all 300ms` | `transition: transform 200ms var(--ease-out)` | Specify exact properties; avoid `all` |
| `transform: scale(0)` | `transform: scale(0.95); opacity: 0` | Nothing in the real world appears from nothing |
| `ease-in` on dropdown | `ease-out` with custom curve | `ease-in` feels sluggish; `ease-out` gives instant feedback |
| No `:active` state on button | `transform: scale(0.97)` on `:active` | Buttons must feel responsive to press |
| `transform-origin: center` on popover | `transform-origin: var(--transform-origin)` | Popovers should scale from their trigger (not modals — modals stay centered) |

## Core Pattern

### Buttons must feel responsive

Add `transform: scale(0.97)` on `:active`. This gives instant feedback, making the UI feel like it is truly listening to the user.

```css
.button {
  transition: transform 160ms var(--ease-out, cubic-bezier(0.23, 1, 0.32, 1));
}

.button:active {
  transform: scale(0.97);
}
```

This applies to any pressable element. The scale should be subtle (0.95-0.98).

### Never animate from scale(0)

Nothing in the real world disappears and reappears completely. Elements animating from `scale(0)` look like they come out of nowhere.

Start from `scale(0.9)` or higher, combined with opacity. Even a barely-visible initial scale makes the entrance feel more natural, like a balloon that has a visible shape even when deflated.

```css
/* Bad */
.entering {
  transform: scale(0);
}

/* Good */
.entering {
  transform: scale(0.95);
  opacity: 0;
}
```

### Make popovers origin-aware

Popovers should scale in from their trigger, not from center. The default `transform-origin: center` is wrong for almost every popover. **Exception: modals.** Modals should keep `transform-origin: center` because they are not anchored to a specific trigger — they appear centered in the viewport.

```css
/* Base UI */
.popover {
  transform-origin: var(--transform-origin);
}
```

### Tooltips: skip delay on subsequent hovers

Delay the first tooltip; once one is open, neighbours open instantly with no animation. CSS: animate RECIPES › Tooltip.

### Use CSS transitions over keyframes for interruptible UI

CSS transitions can be interrupted and retargeted mid-animation. Keyframes restart from zero. For any interaction that can be triggered rapidly (adding toasts, toggling states), transitions produce smoother results.

```css
/* Interruptible - good for UI */
.toast {
  transition: transform 400ms ease;
}

/* Not interruptible - avoid for dynamic UI */
@keyframes slideIn {
  from {
    transform: translateY(100%);
  }
  to {
    transform: translateY(0);
  }
}
```

### Use blur to mask imperfect transitions

When a crossfade still feels off after tuning easing and duration, add `filter: blur(2px)` during the transition, also on a pressed button with its `scale(0.97)`. CSS and limits: animate RECIPES › Masking a crossfade that won't settle.

### Animate enter states with @starting-style

`@starting-style` animates entry without JavaScript and replaces the `useEffect` → `mounted: true` pattern; keep the `data-mounted` flag as the fallback where support is missing. CSS and fallback: animate RECIPES › Toast.

## Quick Reference

**REQUIRED BACKGROUND:** animate — the should-it-animate gate, purposes, easing curves and tokens, durations, spring configs, interruption. Component-level additions:

- Purposes as they show up in components: a toast enters and exits from the same direction, so swipe-to-dismiss feels intuitive (spatial consistency); a morphing feedback button shows the state change (state indication).
- A faster-spinning spinner makes loading feel faster at the same load time.
- **Spring-based mouse interactions:** a visual value tied directly to the pointer feels artificial because it has no motion. Interpolate it with Motion's `useSpring`:

  ```jsx
  import { useSpring } from 'motion/react';

  // Without spring: feels artificial, instant
  const rotation = mouseX * 0.1;

  // With spring: feels natural, has momentum
  const springRotation = useSpring(mouseX * 0.1, { duration: 0.5, bounce: 0.5 });
  ```

- **Interrupted springs reverse in place:** click an expanded item and quickly press Escape; a spring reverses smoothly from its current position where a keyframe would restart.

## CSS Transform Mastery

### translateY with percentages

Percentage values in `translate()` are relative to the element's own size. Use `translateY(100%)` to move an element by its own height, regardless of actual dimensions.

```css
/* Works regardless of drawer height */
.drawer-hidden {
  transform: translateY(100%);
}

/* Works regardless of toast height */
.toast-enter {
  transform: translateY(-100%);
}
```

Prefer percentages over hardcoded pixel values. They are less error-prone and adapt to content.

### scale() scales children too

Unlike `width`/`height`, `scale()` also scales an element's children. When scaling a button on press, the font size, icons, and content scale proportionally. This is a feature, not a bug.

### 3D transforms for depth

`rotateX()`, `rotateY()` with `transform-style: preserve-3d` create real 3D effects in CSS. Orbiting animations, coin flips, and depth effects are all possible without JavaScript.

```css
.wrapper {
  transform-style: preserve-3d;
}

@keyframes orbit {
  from {
    transform: translate(-50%, -50%) rotateY(0deg) translateZ(72px) rotateY(360deg);
  }
  to {
    transform: translate(-50%, -50%) rotateY(360deg) translateZ(72px) rotateY(0deg);
  }
}
```

### transform-origin

Every element has an anchor point from which transforms execute. The default is center. Set it to match where the trigger lives for origin-aware interactions.

## clip-path for Animation

`clip-path` is not just for shapes. It is one of the most powerful animation tools in CSS.

### The inset shape

`clip-path: inset(top right bottom left)` defines a rectangular clipping region. Each value "eats" into the element from that side.

```css
/* Fully hidden from right */
.hidden {
  clip-path: inset(0 100% 0 0);
}

/* Fully visible */
.visible {
  clip-path: inset(0 0 0 0);
}
```

### Tabs with perfect color transitions

Duplicate the tab list. Style the copy as "active" (different background, different text color). Clip the copy so only the active tab is visible. Animate the clip on tab change. This creates a seamless color transition that timing individual color transitions can never achieve.

### Hold-to-delete pattern

Use `clip-path: inset(0 100% 0 0)` on a colored overlay. On `:active`, transition to `inset(0 0 0 0)` over 2s with linear timing. On release, snap back with 200ms `var(--ease-out)`. Add `scale(0.97)` on the button for press feedback. CSS: Asymmetric enter/exit timing below.

### Image reveals on scroll

Start with `clip-path: inset(0 0 100% 0)` (hidden from bottom). Animate to `inset(0 0 0 0)` when the element enters the viewport. Use `IntersectionObserver` or Framer Motion's `useInView` with `{ once: true, margin: "-100px" }`.

### Comparison sliders

Overlay two images. Clip the top one with `clip-path: inset(0 50% 0 0)`. Adjust the right inset value based on drag position. No extra DOM elements needed, fully hardware-accelerated.

## Gesture and Drag Interactions

Full gesture physics live in apple-design. Component-level rules:

- **Momentum dismissal:** dismiss on distance *or* velocity; a flick is enough.

  ```js
  const timeTaken = new Date().getTime() - dragStartTime.current.getTime();
  const velocity = Math.abs(swipeAmount) / timeTaken;

  if (Math.abs(swipeAmount) >= SWIPE_THRESHOLD || velocity > 0.11) {
    dismiss();
  }
  ```

- **Damping / friction at boundaries:** past the natural edge (drawer dragged up at top), the element moves less the further the user drags. Never a hard stop.
- **Pointer capture** once dragging starts, so the drag continues outside the element bounds.
- **Multi-touch protection:** ignore extra touch points after the drag begins, or switching fingers makes the element jump.

  ```js
  function onPress() {
    if (isDragging) return;
    // Start drag...
  }
  ```

## Performance Rules

### Only animate transform and opacity

These properties skip layout and paint, running on the GPU. Animating `padding`, `margin`, `height`, or `width` triggers all three rendering steps.

### Never drive children through a parent CSS variable

CSS variables inherit, so changing one on a parent restyles every child. Write `transform` on the moving element directly; see animation-performance.

### Motion hardware acceleration caveat

From `motion` 14.2, Motion's shorthand properties (`x`, `y`, `scale`, `rotate`) are hardware-accelerated on HTML elements. Before 14.2 they use `requestAnimationFrame` on the main thread, so on those versions use the full `transform` string for hardware acceleration:

```jsx
// motion 14.2+: hardware accelerated. Before 14.2: main thread, drops frames under load
<motion.div animate={{ x: 100 }} />

// Hardware accelerated in every version (stays smooth even when main thread is busy)
<motion.div animate={{ transform: "translateX(100px)" }} />
```

Some Motion animations still run on the main thread in every version: layout animations (`layout`, `layoutId`), animations with `onUpdate` or `transformTemplate`, inertia (drag momentum), and values driven every frame by a motion value (drag, `useTransform`).

This matters when the browser is simultaneously loading content, running scripts, or painting.

### CSS animations beat JS under load

CSS animations run off the main thread. When the browser is busy loading a new page, animations that run on `requestAnimationFrame` (including Motion layout animations) drop frames. CSS animations remain smooth. Use CSS for predetermined animations; JS for dynamic, interruptible ones.

### Use WAAPI for programmatic CSS animations

The Web Animations API gives you JavaScript control with CSS performance. Hardware-accelerated, interruptible, and no library needed.

```js
element.animate([{ clipPath: 'inset(0 0 100% 0)' }, { clipPath: 'inset(0 0 0 0)' }], {
  duration: 1000,
  fill: 'forwards',
  easing: 'cubic-bezier(0.77, 0, 0.175, 1)',
});
```

## Accessibility

Reduced motion means fewer and gentler animations, not zero: keep opacity and color transitions, remove movement. Full policy: accessible-animation.

```css
@media (prefers-reduced-motion: reduce) {
  .element {
    animation: fade 0.2s ease;
    /* No transform-based motion */
  }
}
```

```jsx
const shouldReduceMotion = useReducedMotion();
const closedX = shouldReduceMotion ? 0 : '-100%';
```

Gate hover animations behind `@media (hover: hover) and (pointer: fine)`; touch devices fire hover on tap (see mobile-native).

## Component Principles

From building Sonner; they apply to any component:

1. **Good defaults matter more than options.** Ship beautiful out of the box. Most users never customize. The default easing, timing, and visual design should be excellent.

2. **Handle edge cases invisibly.** Pause toast timers when the tab is hidden. Fill gaps between stacked toasts with pseudo-elements to maintain hover state. Capture pointer events during drag. Users never notice these, and that is exactly right.

### Cohesion matters

Sonner's animation feels satisfying partly because the whole experience is cohesive. The easing and duration fit the vibe of the library. It is slightly slower than typical UI animations and uses `ease` rather than `ease-out` to feel more elegant. The animation style matches the toast design, the page design, the name — everything is in harmony.

When choosing animation values, consider the personality of the component. A playful component can be bouncier. A professional dashboard should be crisp and fast. Match the motion to the mood.

### The opacity + height combination

When items enter and exit a list (like Family's drawer), the opacity change must work well with the height animation. This is often trial and error. There is no formula — you adjust until it feels right.

### Asymmetric enter/exit timing

Pressing should be slow when it needs to be deliberate (hold-to-delete: 2s linear), but release should always be snappy (200ms `var(--ease-out)`). This pattern applies broadly: slow where the user is deciding, fast where the system is responding.

```css
/* Release: fast */
.overlay {
  transition: clip-path 200ms var(--ease-out, cubic-bezier(0.23, 1, 0.32, 1));
}

/* Press: slow and deliberate */
.button:active .overlay {
  transition: clip-path 2s linear;
}
```

## Stagger Animations

When several elements enter together, delay each by 30-80ms (e.g. `nth-child` delays 0/50/100/150ms on a `300ms var(--ease-out)` fade from `translateY(8px)`). Never block interaction while a stagger plays. Ordering and overlap: choreograph.

## Debugging Feel

Slow motion (2–5× duration or the DevTools animation inspector) and what to look for in it, frame-by-frame inspection in the Chrome DevTools Animations panel, real-device testing for touch interactions, and fresh eyes the next day: improve-animations, AUDIT.md "Debugging feel". Real-device setup (USB, dev server by LAN IP, Safari remote devtools; the Xcode Simulator still misses touch feel): mobile-native.

## Common Mistakes

| Issue                                      | Fix                                                              |
| ------------------------------------------ | ---------------------------------------------------------------- |
| `transition: all`                          | Specify exact properties: `transition: transform 200ms var(--ease-out)` |
| `scale(0)` entry animation                 | Start from `scale(0.95)` with `opacity: 0`                       |
| `ease-in` on UI element                    | Switch to `ease-out` or custom curve                             |
| `transform-origin: center` on popover      | Set to trigger location or use Base UI's `var(--transform-origin)` (modals are exempt — keep centered) |
| Animation on keyboard action               | Remove animation entirely                                        |
| Duration > 300ms on UI element             | Reduce to 150-250ms; only modals and drawers may run longer (see animate) |
| Hover animation without media query        | Add `@media (hover: hover) and (pointer: fine)`                  |
| Motion `x`/`y` props under load (pre-14.2) | Upgrade to 14.2+, or use `transform: "translateX()"`             |
| Same enter/exit transition speed           | Exit ~20% faster than enter; where the user decides, go asymmetric (hold-to-confirm: press 2s linear, release 200ms `var(--ease-out)`) |
| Elements all appear at once                | Add stagger delay (30-80ms between items)                        |
