# Patterns and profiling

Read when confirming a fix is compositor-only or when a full runnable example is needed. Reduced-motion patterns: see accessible-animation.

## Accordion with grid height (no JS measurement)

```html
<button class="acc-trigger" aria-expanded="false">Details</button>
<div class="acc-wrap"><div class="acc-content">…content…</div></div>
```

```css
.acc-wrap {
  display: grid;
  grid-template-rows: 0fr;
  transition: grid-template-rows 200ms var(--ease-out, cubic-bezier(0.23, 1, 0.32, 1)); /* animate's accordion duration and token */
}
.acc-wrap.open { grid-template-rows: 1fr; }
.acc-content { overflow: hidden; min-height: 0; }

@media (prefers-reduced-motion: reduce) {
  .acc-wrap { transition: none; }
}
```

```js
trigger.addEventListener('click', () => {
  const open = wrap.classList.toggle('open');
  trigger.setAttribute('aria-expanded', String(open));
});
```

## FLIP reorder list (batched reads)

```js
function flipReorder(container, mutate) {
  const items = [...container.children];
  const firsts = new Map(items.map((el) => [el, el.getBoundingClientRect()])); // all reads

  mutate(); // e.g. sort/reinsert children

  items.forEach((el) => {
    const first = firsts.get(el);
    const last = el.getBoundingClientRect();
    const dx = first.left - last.left;
    const dy = first.top - last.top;
    if (dx || dy) {
      el.animate(
        [{ transform: `translate(${dx}px, ${dy}px)` }, { transform: 'none' }],
        { duration: 300, easing: 'cubic-bezier(0.23, 1, 0.32, 1)' } // animate's --ease-out
      );
    }
  });
}
```

Reading every rect *before* mutating, and using `animate()` (compositor), keeps a 50-item reorder smooth.

## Just-in-time will-change

```js
el.addEventListener('pointerenter', () => { el.style.willChange = 'transform'; });
el.addEventListener('transitionend', () => { el.style.willChange = 'auto'; });
```

Promote on intent, demote when the animation ends, so layers don't accumulate.

## Profiling: prove it's compositor-only

1. Open DevTools > **Performance**. Record while the animation runs.
2. Inspect the flame chart frames during the animation:
   - **Purple "Layout"** or **green "Paint"** bars on every frame → still hitting layout/paint; the animation is not compositor-only. Find the offending property.
   - Only **"Composite Layers"** / GPU work per frame → success.
3. Use **Rendering** tab tools:
   - **Paint flashing** — green flashes show repainted regions; a good transform/opacity animation flashes nothing.
   - **Layer borders** — confirms which elements are on their own compositor layer (watch for too many from over-using `will-change`).
   - **Frame Rendering Stats / FPS meter** — confirm a stable 60/120fps.
4. The **Layers** panel shows layer count and memory; excessive layers indicate `will-change` overuse.

## Parallax without scroll-jank

Drive parallax with `transform: translate3d()` updated inside a single `requestAnimationFrame` loop reading `scrollY` once per frame — never read layout per element per frame.

```js
let ticking = false;
addEventListener('scroll', () => {
  if (!ticking) {
    requestAnimationFrame(() => {
      const y = window.scrollY;              // single read
      layers.forEach((l, i) => {             // writes only
        l.style.transform = `translate3d(0, ${y * (0.1 * (i + 1))}px, 0)`;
      });
      ticking = false;
    });
    ticking = true;
  }
}, { passive: true });
```

`{ passive: true }` lets the browser scroll without waiting on the handler.

## Headless verification

Freeze frames with the harness in animate (`references/standalone-harness.md`).

Screenshot start, mid and end: check no `scaleX` text distortion and that FLIP lands on the real layout. The CDP trace check for cost is in the same harness file.
