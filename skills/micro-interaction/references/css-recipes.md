# CSS Micro-interaction Recipes

Modern CSS handles most UI motion with zero JavaScript, including enter/exit and `display` toggles. Baseline-available in current Chrome/Edge/Safari/Firefox (verify `@starting-style` and `allow-discrete` for your support floor; degrade to instant show/hide otherwise).

## Enter animation on first render: @starting-style

`@starting-style` supplies the values an element transitions FROM the first time it renders (or becomes shown). Without it, there is no "previous" state to transition from, so newly-inserted elements snap in.

```css
.menu {
  opacity: 1;
  transform: translateY(0);
  transition: opacity 0.2s var(--ease-out, cubic-bezier(0.23, 1, 0.32, 1)), transform 0.2s var(--ease-out, cubic-bezier(0.23, 1, 0.32, 1));
}
@starting-style {
  .menu { opacity: 0; transform: translateY(-8px); }
}
```

## Animating to/from display:none: transition-behavior: allow-discrete

`display` and `content-visibility` are discrete properties — normally they flip instantly, killing exit animations. `allow-discrete` lets them flip at the correct moment (kept visible during exit, swapped at the end).

```css
.drawer {
  transition:
    transform 0.25s var(--ease-out, cubic-bezier(0.23, 1, 0.32, 1)),
    opacity 0.25s var(--ease-out, cubic-bezier(0.23, 1, 0.32, 1)),
    display 0.25s allow-discrete; /* keep displayed through the exit */
}
.drawer[hidden] {            /* closed state */
  opacity: 0;
  transform: translateX(100%);
  display: none;
}
@starting-style {
  .drawer:not([hidden]) { opacity: 0; transform: translateX(100%); }
}
```

Shorthand alternative: `transition-behavior: allow-discrete;` applies to all discrete properties in the `transition` list.

## Popover / dialog exit animation (top-layer)

Native `popover` and `<dialog>` live in the top layer via the `overlay` property, which is also discrete — animate it too:

```css
[popover] {
  transform-origin: top center; /* the edge facing the invoking button (here: popover below it); <dialog> stays centered */
  opacity: 0;
  transform: scale(0.95);
  transition: opacity 0.2s var(--ease-out, cubic-bezier(0.23, 1, 0.32, 1)), transform 0.2s var(--ease-out, cubic-bezier(0.23, 1, 0.32, 1)), overlay 0.2s allow-discrete, display 0.2s allow-discrete;
}
[popover]:popover-open { opacity: 1; transform: scale(1); }
@starting-style {
  [popover]:popover-open { opacity: 0; transform: scale(0.95); }
}
```

This gives a fully CSS-driven open AND close animation for `<button popovertarget>` popovers with no JS.

## Press / hover / focus feedback

```css
.btn {
  transition: transform 0.12s var(--ease-overshoot, cubic-bezier(0.34, 1.56, 0.64, 1)), box-shadow 0.2s ease;
}
@media (hover: hover) and (pointer: fine) {
  .btn:hover { transform: translateY(-1px); box-shadow: 0 4px 12px rgba(0,0,0,.15); }
}
.btn:active { transform: translateY(0) scale(0.97); transition-duration: 0.1s; } /* snappy press */
.btn:focus-visible { outline: 2px solid #3b82f6; outline-offset: 2px; }
```

Use `:focus-visible` (not `:focus`) so keyboard users get a ring but mouse clicks don't.

## Animated toggle / switch

```css
.switch { width: 44px; height: 24px; border-radius: 999px; background: #cbd5e1;
  transition: background 0.2s ease; }
.switch[aria-checked="true"] { background: #22c55e; }
.switch::after {
  content: ""; width: 20px; height: 20px; border-radius: 50%; background: #fff;
  transform: translateX(2px);
  transition: transform 0.22s var(--ease-overshoot, cubic-bezier(0.34, 1.56, 0.64, 1));
}
.switch[aria-checked="true"]::after { transform: translateX(22px); }
```

The `--ease-overshoot` curve (animate) gives the knob a satisfying snap.

## Loading spinner and pulse

```css
@keyframes spin { to { transform: rotate(360deg); } }
.spinner { animation: spin 0.8s linear infinite; }

@keyframes pulse { 0%,100% { opacity: 1; } 50% { opacity: 0.5; } }
.skeleton { animation: pulse 1.5s ease-in-out infinite; }
```

## Animatable custom properties with @property

Plain CSS variables animate discretely. Register them with `@property` to give them a type so they interpolate smoothly — enables gradient angle, number counters, and themed motion.

```css
@property --angle { syntax: "<angle>"; inherits: false; initial-value: 0deg; }

.gradient-border {
  background: conic-gradient(from var(--angle), #6366f1, #ec4899, #6366f1);
  transition: --angle 0.4s ease;
}
.gradient-border:hover { --angle: 360deg; }
```

## Accordion height (modern: interpolate-size)

Animating `height: auto` historically required JS measurement. With `interpolate-size: allow-keywords`, transitions to/from intrinsic sizes work:

```css
:root { interpolate-size: allow-keywords; }
.accordion__panel {
  height: 0; overflow: hidden;
  transition: height 0.2s var(--ease-out, cubic-bezier(0.23, 1, 0.32, 1));
}
.accordion__panel[data-open] { height: auto; }
```

Fallback for unsupported browsers: animate `grid-template-rows: 0fr -> 1fr` on a wrapper.

## Reduced motion (always include)

Global `0.01ms` reset and the tiered overrides that keep opacity fades: accessible-animation. Never remove feedback entirely; remove only large/spatial motion.
