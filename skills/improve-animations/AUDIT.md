# Animation Audit Playbook

The eight audit categories, the hunt list for each, and the exact values to cite in findings, suggestions and plans. Distilled from Emil Kowalski's design engineering philosophy ([emilkowal.ski](https://emilkowal.ski/)). Never approximate a value that appears here — copy it.

## 1. Purpose & frequency

Whether motion should exist at all is decided by the gate in SKILL.md (frequency, purpose, budget).

| Frequency | Decision |
| --- | --- |
| 100+ times/day (keyboard shortcuts, command palette toggle) | No animation. Ever. |
| Tens of times/day (hover effects, list navigation) | Remove or drastically reduce |
| Occasional (modals, drawers, toasts) | Standard animation |
| Rare / first-time (onboarding, feedback, celebrations) | Can add delight |

The strongest fix is often **delete the animation**. Hunt for motion that rarely survives the gate:

**Keyboard and high-frequency**
- Command palette, menu or dialog opened by a shortcut with an enter/exit animation.
- Tab switches, segmented controls and sidebar navigation that slide or crossfade.
- Route or page transitions inside the app (not on marketing pages).
- Hover transforms on rows and list items users sweep the cursor across.

**Decoration**
- Fade-in-on-scroll on every section (`whileInView`, IntersectionObserver reveal classes, AOS, `animate-fade-in` utilities).
- Hover `scale` or lift on cards that aren't the primary action.
- Infinite loops: pulsing badges, gradient orbs, glowing borders, spinning icons that aren't loading indicators.
- Staggered entrances on lists the user loads many times a day.

**Functional data**
- Charts that redraw from zero on every mount or refresh.
- Numbers that count up on page load rather than on a change.
- Table rows that animate in when data loads.
- Decorative mouse-tracking is fine on a marketing page; on a functional graph in a banking app, no animation is better.

**Over-engineering**
- Spinners on operations that resolve in under 300ms — the flash reads as a glitch.
- Skeleton shimmer on content that loads in under 300ms.
- `transition: all` — list only the properties that need to transition, or none.

## 2. Easing & duration

Decision order for easing:

- Entering or exiting → **`ease-out`** (starts fast, feels responsive)
- Moving / morphing on screen → **`ease-in-out`**
- Hover / color change → **`ease`**
- Constant motion (marquee, progress) → **`linear`**
- Default → **`ease-out`**

**`ease-in` on UI is always a finding** — it starts slow, delaying the exact moment the user is watching. `ease-out` at 200ms *feels* faster than `ease-in` at 200ms. Built-in CSS easings are too weak for deliberate motion; introduce strong custom curves as tokens, matching repo conventions:

```css
--ease-out: cubic-bezier(0.23, 1, 0.32, 1);        /* strong ease-out for UI */
--ease-in-out: cubic-bezier(0.77, 0, 0.175, 1);    /* strong ease-in-out for on-screen movement */
--ease-drawer: cubic-bezier(0.32, 0.72, 0, 1);     /* iOS-like drawer curve (Ionic) */
```

Find other curves at [easing.dev](https://easing.dev/) or [easings.co](https://easings.co/) — don't hand-roll from scratch.

Duration budgets — **UI animations stay under 300ms**:

| Element | Duration |
| --- | --- |
| Button press feedback | 100–160ms |
| Tooltips, small popovers | 125–200ms |
| Dropdowns, selects | 150–250ms |
| Modals, drawers | 200–500ms |
| Marketing / explanatory | Can be longer |

A 180ms dropdown feels more responsive than a 400ms one. Faster spinners make a load feel faster (same actual time). Tooltips after the first in a toolbar skip delay and animation, which makes the toolbar feel faster.

Hunt for: `ease-in` anywhere, bare `ease`/`linear` on entrances, durations > 300ms on UI elements, delay + animation on every tooltip in a toolbar.

## 3. Physicality & origin

- **Never `scale(0)`** — nothing in the real world appears from nothing. Target: `scale(0.9–0.97)` + `opacity: 0`.
- **Popovers/dropdowns/tooltips scale from their trigger**, not center:
  ```css
  .popover { transform-origin: var(--transform-origin); } /* Base UI */
  ```
  **Modals are exempt** — they appear centered; `transform-origin: center` is correct there.
- **Press feedback**: `transform: scale(0.97)` on `:active` with `transition: transform 160ms ease-out`. Keep it subtle (0.95–0.98). Applies to any pressable element. `scale()` scales children too (font, icons, content) — a feature here.

Transform tools:

- **`translate` percentages** are relative to the element's own size — `translateY(100%)` moves by the element's height regardless of dimensions (how Sonner/Vaul position toasts and drawers). Prefer them over hardcoded px.
- **3D**: `rotateX/Y` + `transform-style: preserve-3d` for depth, orbit or flip without JS.
- **`clip-path: inset(t r b l)`**: each value eats in from that side. Uses: reveal-on-scroll (`inset(0 0 100% 0)` → `inset(0 0 0 0)`), hold-to-delete overlay, seamless tab color transitions (duplicate + clip the active copy), comparison sliders.

Hunt for: `scale(0)`, pure-fade entrances with no initial transform, `transform-origin: center` (or none) on trigger-anchored elements, pressable elements with no press feedback.

## 4. Interruptibility

CSS **transitions** retarget from the current state mid-animation; **keyframes** restart from zero. Anything triggered rapidly or reversible mid-motion (toasts stacking, toggles, drags, expand/collapse) uses transitions or springs.

```css
/* Interruptible — good for dynamic UI */
.toast { transition: transform 400ms ease; }

/* Not interruptible — avoid for dynamic UI */
@keyframes slideIn { from { transform: translateY(100%); } to { transform: translateY(0); } }
```

Entry without JS — `@starting-style`:

```css
.toast {
  opacity: 1; transform: translateY(0);
  transition: opacity 400ms ease, transform 400ms ease;
  @starting-style { opacity: 0; transform: translateY(100%); }
}
```

Legacy fallback: `useEffect(() => setMounted(true), [])` + a `data-mounted` attribute.

**Springs** simulate physics and settle on parameters instead of a fixed duration. They keep velocity when interrupted, so they suit gestures users may reverse mid-motion. Use for drag with momentum, "alive" elements (Dynamic Island), interruptible gestures, decorative mouse-tracking.

```js
// Apple-style (easier to reason about) — recommended
{ type: "spring", duration: 0.5, bounce: 0.2 }

// Traditional physics (more control)
{ type: "spring", mass: 1, stiffness: 100, damping: 10 }
```

Keep bounce subtle (0.1–0.3); avoid it in most UI and reserve visible bounce for drag-to-dismiss and playful moments. For decorative mouse interactions, interpolate with `useSpring` instead of tying the value directly to the pointer (direct = artificial, no momentum).

**Asymmetric timing**: slow where the user is deciding (press, hold, destructive confirm), fast where the system responds.

```css
.overlay { transition: clip-path 200ms ease-out; }            /* release: fast */
.button:active .overlay { transition: clip-path 2s linear; }  /* press: slow, deliberate */
```

**Gestures and drag**:

- **Momentum dismissal**: compute velocity (`Math.abs(distance)/elapsedMs`) and dismiss if `> ~0.11`; don't require crossing a distance threshold. A flick should be enough.
- **Damping at boundaries**: past a natural edge, the element moves less the further you drag. Allow over-drag with rising friction, never an invisible wall.
- **Pointer capture** once dragging starts, so the drag continues when the pointer leaves bounds.
- **Multi-touch protection**: ignore extra touch points after the drag begins (`if (isDragging) return`) — prevents jumps.

Hunt for: `@keyframes` on toasts/toggles/rapidly triggered UI, gesture handlers that tween with fixed-duration keyframes, drags without velocity-based dismissal, hard stops at drag boundaries, symmetric press-and-release timing.

## 5. Performance

- **Animate `transform` and `opacity` only** — they skip layout and paint and run on the GPU. `width`/`height`/`margin`/`padding`/`top`/`left` trigger layout + paint + composite.
- **`transition: all`** animates unintended properties off-GPU — always a finding.
- **Don't drive child transforms via a CSS variable on the parent** — it recalcs styles for all children:
  ```js
  element.style.setProperty('--swipe-amount', `${d}px`); // bad: recalc on all children
  element.style.transform = `translateY(${d}px)`;        // good: only this element
  ```
- **Motion shorthands are hardware-accelerated from `motion` 14.2** on HTML elements. Before 14.2, `x`/`y`/`scale` run on the main thread via rAF and drop frames under load: upgrade, or use the full transform string. Layout animations (`layout`, `layoutId`) run on the main thread in every version.
  ```jsx
  <motion.div animate={{ x: 100 }} />                          // motion 14.2+: hardware accelerated
  <motion.div animate={{ transform: "translateX(100px)" }} />  // hardware accelerated in every version
  ```
- **CSS and WAAPI beat rAF-based JS under load** — rAF animations stutter while the browser loads, scripts and paints. Use CSS for predetermined motion (transitions, `@starting-style`, WAAPI), JS/springs for dynamic, interruptible, gesture-driven motion.
- **WAAPI** gives JS control with CSS performance (hardware-accelerated, interruptible, no library):
  ```js
  element.animate([{ clipPath: 'inset(0 0 100% 0)' }, { clipPath: 'inset(0 0 0 0)' }],
    { duration: 1000, fill: 'forwards', easing: 'cubic-bezier(0.77, 0, 0.175, 1)' });
  ```
- Keep transition-time `filter: blur()` under 20px — heavy blur is expensive, especially in Safari.

Hunt for: `transition: all`, animated layout properties, Motion shorthand props on busy pages (before 14.2), layout animations on busy pages, `setProperty('--x', …)` driving child transforms, rAF loops doing what CSS could. For diagnosing jank beyond these, see animation-performance.

## 6. Accessibility

```css
@media (prefers-reduced-motion: reduce) {
  .element { animation: fade 0.2s ease; } /* keep opacity/color, drop movement */
}
@media (hover: hover) and (pointer: fine) {
  .element:hover { transform: scale(1.05); } /* touch fires false hovers on tap */
}
```

```jsx
const reduce = useReducedMotion();
const closedX = reduce ? 0 : '-100%';
```

Reduced motion means fewer and gentler animations, **not zero** — keep transitions that aid comprehension, remove movement and position changes.

Hunt for: movement with no `prefers-reduced-motion` handling, ungated `:hover` motion, reduced-motion implementations that remove all feedback.

## 7. Cohesion & tokens

- Motion matches the product's personality — playful can be bouncier, a professional dashboard stays crisp and fast. Sonner feels right partly because easing, duration, design and even the name are in harmony: slightly slower, `ease` rather than `ease-out`, to feel elegant.
- Curves and durations live as shared tokens. Five hand-typed cubic-beziers that almost match is a consolidation finding.
- Group entrances stagger 30–80ms between items; longer delays feel slow. Stagger is decorative — it never blocks interaction.
  ```css
  .item { opacity: 0; transform: translateY(8px); animation: fadeIn 300ms ease-out forwards; }
  .item:nth-child(2) { animation-delay: 50ms; }
  .item:nth-child(3) { animation-delay: 100ms; }
  @keyframes fadeIn { to { opacity: 1; transform: translateY(0); } }
  ```
- A crossfade that still shows two overlapping states after tuning easing and duration can be masked with subtle `filter: blur(2px)` during the transition, blending them into one perceived transformation.
- Opacity + height on entering/exiting list items has no formula — adjust until it feels right.

Hunt for: near-identical duplicated easings/durations, one bouncy component in a crisp app, list/grid entrances with no stagger, crossfades that visibly double-expose.

## 8. Missed opportunities

Places that don't animate but should. Every candidate passes the gate in SKILL.md; report a handful grounded in UX seams you observed, not a wishlist.

**Feedback gaps**
- Pressable elements with no `:active` state → `transform: scale(0.97)` with `transition: transform 160ms ease-out` (subtle: 0.95–0.98).
- Destructive actions confirmed with a plain click where hold-to-confirm would prevent slips → `clip-path: inset(0 100% 0 0)` overlay, 2s linear on press, 200ms ease-out snap-back on release.

**Teleporting state**
- Content that swaps, appears or vanishes instantly (conditional renders, route content, expanding sections) → fade/scale entrance from `scale(0.95–0.97)` + `opacity: 0`, `ease-out`; `@starting-style` for entry without JS.
- Accordions/collapses that snap open → height + opacity transition.
- List items added/removed with no bridge, on a list that isn't high-frequency → enter/exit transitions, not keyframes, so rapid triggers retarget.

**Missing spatial story**
- Panels, popovers and menus that appear with no connection to their trigger → scale in with `transform-origin` at the trigger (Base UI: `var(--transform-origin)`).
- Dismissable surfaces (toasts, sheets) that exit differently than they entered → same path both ways, with `translateY(100%)` percentages or `clip-path: inset()` reveals, not hardcoded pixels.

**Group entrances**
- A grid or list that pops in all at once on a page users see occasionally → 30–80ms stagger.

**Gesture seams**
- Draggable/swipeable elements that snap with no physics → springs (`{ type: "spring", duration: 0.5, bounce: 0.2 }`), velocity-based dismissal, rubber-banding at boundaries (§4).

**The delight budget**
- Rare, high-emotion moments rendered flat — first-run, empty states, success/completion, celebration. The only places bounce, generous stagger or a longer beat are welcome.

Sweeps: conditional renders with no transition (`{isOpen &&`, `display: none` toggles), `onClick` handlers on elements with no `:active`/transition styles, `details`/accordion markup, drag handlers, `.map(` renders of entering lists, empty-state and success components.

## Debugging feel

Prescribe these when feel can't be judged from code, and in every plan's feel check:

- **Slow motion**: bump duration 2–5× or use the DevTools animation inspector. Check that colors crossfade cleanly, easing doesn't stop abruptly, `transform-origin` is right, and coordinated properties stay in sync.
- **Frame-by-frame**: the Chrome DevTools Animations panel reveals timing drift between coordinated properties.
- **Real devices** for gestures (drawers, swipe): connect a phone, open the dev server by IP, use Safari remote devtools.
- **Fresh eyes the next day** — imperfections invisible during development surface later.
