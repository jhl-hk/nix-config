# Animation Audit Playbook

The eight audit categories, the hunt list for each, and the exact values to cite in findings, suggestions and plans. Distilled from Emil Kowalski's design engineering philosophy ([emilkowal.ski](https://emilkowal.ski/)). Curves, durations and springs: copy from animate. Every other value: copy from here. Never approximate.

## 1. Purpose & frequency

Whether motion should exist at all is decided by the gate in SKILL.md (frequency, purpose, budget); the frequency tiers are animate's.

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

**REQUIRED BACKGROUND:** animate — the easing table, curve tokens (`--ease-out`, `--ease-in-out`, `--ease-drawer`, `--ease-overshoot`), strength families, duration table and exit timing. Every replacement value in a finding comes from there; introduce curves as tokens matching repo conventions.

- **`ease-in` on UI is always a finding** — it delays the exact moment the user is watching.
- Built-in CSS easing on a deliberate animation is a finding: too weak; replace with animate's strong curves.
- A hand-rolled cubic-bezier is a finding; the replacement comes from animate's tables or [easing.dev](https://easing.dev/) / [easings.co](https://easings.co/).
- **UI animations stay under 300ms**; only modals and drawers may run longer.
- Faster spinners make a load feel faster (same actual time). Tooltips after the first in a toolbar skip delay and animation, which makes the toolbar feel faster.

Hunt for: `ease-in` anywhere, bare `ease`/`linear` on entrances, durations > 300ms on UI elements, delay + animation on every tooltip in a toolbar.

## 3. Physicality & origin

- **Never `scale(0)`** — nothing in the real world appears from nothing. Target: `scale(0.9–0.97)` + `opacity: 0`.
- **Popovers/dropdowns/tooltips scale from their trigger**, not center:
  ```css
  .popover { transform-origin: var(--transform-origin); } /* Base UI */
  ```
  **Modals are exempt** — they appear centered; `transform-origin: center` is correct there.
- **Press feedback**: `transform: scale(0.97)` on `:active` with `transition: transform 160ms var(--ease-out)`. Keep it subtle (0.95–0.98). Applies to any pressable element. `scale()` scales children too (font, icons, content) — a feature here.

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

Entry without JS: `@starting-style`, with the `data-mounted` flag as legacy fallback. Fix: animate RECIPES › Toast.

**Springs** settle on parameters instead of a fixed duration and keep velocity when interrupted, so they suit gestures users may reverse mid-motion: drag with momentum, "alive" elements (Dynamic Island), interruptible gestures, decorative mouse-tracking. Configs: animate (`{ type: "spring", duration, bounce }`).

Flag visible bounce outside drag-to-dismiss and playful moments. For decorative mouse interactions, interpolate with `useSpring` instead of tying the value directly to the pointer (direct = artificial, no momentum).

**Asymmetric timing**: slow where the user is deciding (press, hold, destructive confirm), fast where the system responds.

```css
.overlay { transition: clip-path 200ms var(--ease-out, cubic-bezier(0.23, 1, 0.32, 1)); }     /* release: fast */
.button:active .overlay { transition: clip-path 2s linear; }  /* press: slow, deliberate */
```

**Gestures and drag**: dismiss on velocity (`> ~0.11` px/ms), not only distance; damping with rising friction past boundaries, never an invisible wall; pointer capture once dragging starts; multi-touch protection (`if (isDragging) return`). Fix: animate RECIPES › Drag to dismiss.

Hunt for: `@keyframes` on toasts/toggles/rapidly triggered UI, gesture handlers that tween with fixed-duration keyframes, drags without velocity-based dismissal, hard stops at drag boundaries, symmetric press-and-release timing.

## 5. Performance

- **Animate `transform` and `opacity` only** — they skip layout and paint and run on the GPU. `width`/`height`/`margin`/`padding`/`top`/`left` trigger layout + paint + composite.
- **`transition: all`** animates unintended properties off-GPU — always a finding.
- **Don't drive child transforms via a CSS variable on the parent** — it recalcs styles for all children; write `transform` on the element itself. See animation-performance.
- **Motion shorthands are hardware-accelerated from `motion` 14.2** on HTML elements. Before 14.2, `x`/`y`/`scale` run on the main thread via rAF and drop frames under load: upgrade, or use the full transform string (snippet: animate, Implementation › Properties). Layout animations (`layout`, `layoutId`) run on the main thread in every version.
- **CSS and WAAPI beat rAF-based JS under load** — rAF animations stutter while the browser loads, scripts and paints. Use CSS for predetermined motion (transitions, `@starting-style`, WAAPI), JS/springs for dynamic, interruptible, gesture-driven motion.
- **WAAPI** gives JS control with CSS performance (hardware-accelerated, interruptible, no library). Fix: animate RECIPES › Programmatic, without a library.
- Keep transition-time `filter: blur()` under 20px — heavy blur is expensive, especially in Safari.

Hunt for: `transition: all`, animated layout properties, Motion shorthand props on busy pages (before 14.2), layout animations on busy pages, `setProperty('--x', …)` driving child transforms, rAF loops doing what CSS could. For diagnosing jank beyond these, see animation-performance.

## 6. Accessibility

Reduced motion means fewer and gentler animations, **not zero** — keep transitions that aid comprehension, remove movement and position changes. Hover motion is gated behind `@media (hover: hover) and (pointer: fine)`; touch fires false hovers on tap. Fix: animate, Implementation › Reduced motion and hover gating; policy: accessible-animation.

Hunt for: movement with no `prefers-reduced-motion` handling, ungated `:hover` motion, reduced-motion implementations that remove all feedback.

## 7. Cohesion & tokens

- Motion matches the product's personality — playful can be bouncier, a professional dashboard stays crisp and fast. Sonner feels right partly because easing, duration, design and even the name are in harmony: slightly slower, `ease` rather than `ease-out`, to feel elegant.
- Curves and durations live as shared tokens. Five hand-typed cubic-beziers that almost match is a consolidation finding.
- Group entrances stagger 30–80ms between items (animate); longer delays feel slow. Stagger is decorative — it never blocks interaction. Fix: animate RECIPES › Stagger a group entrance.
- A crossfade that still shows two overlapping states after tuning easing and duration can be masked with subtle `filter: blur(2px)` during the transition, blending them into one perceived transformation. Fix: animate RECIPES › Masking a crossfade that won't settle.
- Opacity + height on entering/exiting list items has no formula — adjust until it feels right.

Hunt for: near-identical duplicated easings/durations, one bouncy component in a crisp app, list/grid entrances with no stagger, crossfades that visibly double-expose.

## 8. Missed opportunities

Places that don't animate but should. Every candidate passes the gate in SKILL.md; report a handful grounded in UX seams you observed, not a wishlist.

**Feedback gaps**
- Pressable elements with no `:active` state → `transform: scale(0.97)` with `transition: transform 160ms var(--ease-out)` (subtle: 0.95–0.98).
- Destructive actions confirmed with a plain click where hold-to-confirm would prevent slips → `clip-path: inset(0 100% 0 0)` overlay, 2s linear on press, 200ms `var(--ease-out)` snap-back on release.

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
- Draggable/swipeable elements that snap with no physics → springs (config: animate), velocity-based dismissal, rubber-banding at boundaries (§4).

**The delight budget**
- Rare, high-emotion moments rendered flat — first-run, empty states, success/completion, celebration. The only places bounce, generous stagger or a longer beat are welcome.

Sweeps: conditional renders with no transition (`{isOpen &&`, `display: none` toggles), `onClick` handlers on elements with no `:active`/transition styles, `details`/accordion markup, drag handlers, `.map(` renders of entering lists, empty-state and success components.

## Debugging feel

Prescribe these when feel can't be judged from code, and in every plan's feel check:

- **Slow motion**: bump duration 2–5× or use the DevTools animation inspector. Check that colors crossfade cleanly, easing doesn't stop abruptly, `transform-origin` is right, and coordinated properties stay in sync.
- **Frame-by-frame**: the Chrome DevTools Animations panel reveals timing drift between coordinated properties.
- **Real devices** for gestures (drawers, swipe): connect a phone, open the dev server by IP, use Safari remote devtools.
- **Fresh eyes the next day** — imperfections invisible during development surface later.
