Push an interface past conventional limits with the full power of the browser: a table that handles a million rows, a dialog that morphs from its trigger, a form with streaming validation, a cinematic page transition.

Context decides what "extraordinary" means. A particle system suits a creative portfolio, not a settings page; a settings page earns instant optimistic saves and animated state transitions instead.

## Propose before building

This command misfires most easily. Do not start implementing.

1. Think through 2–3 directions: different techniques, levels of ambition, aesthetics. Describe how each would look and feel.
2. Ask the user to pick and wait. Put each direction's description and trade-offs (browser support, performance cost, complexity) inside the option itself; a structured question hides text written beside it.
3. Build only the confirmed direction.

## Assess what "extraordinary" means here

Ask what would make a user of this specific interface say "that's nice".

- **Visual and marketing surfaces:** sensory: scroll-driven reveal, shader background, cinematic transition, cursor-reactive generative art.
- **Functional UI:** how it feels: a dialog morphing from its button, 100k-row tables via virtual scrolling, instant streaming validation, physical drag-and-drop.
- **Performance-critical UI:** invisible: filtering 50k items without a flicker, a form that never blocks the main thread.
- **Data-heavy interfaces:** fluid: Canvas/WebGL rendering for large datasets, animated transitions between data states.

This command changes how an interface feels, not what the product does. Real-time collaboration, offline support and new backend capabilities are product decisions.

## Toolkit

Craft detail lives in other skills; use them for implementation:

- Springs, gesture physics, translucency: `apple-design`.
- Scroll-driven timelines, pinning, SplitText, Flip: `gsap-web`.
- View Transitions, shared-element and layout transitions, motion/react: `micro-interaction`.
- Blur and glass panels: `glassmorphism`.
- Frame budget, compositing, `will-change`: `animation-performance`.

Platform capabilities to consider:

- **Transitions:** View Transitions API (same-document in all browsers; cross-document not in Firefox); `@starting-style` for entry from `display: none`.
- **Scroll:** `animation-timeline: scroll()` (Chrome/Edge/Safari; Firefox behind a flag), always with a static fallback.
- **Rendering:** WebGL (Three.js, OGL, regl); WebGPU (Chrome/Edge, Safari 26+, Firefox on Windows/macOS) with a WebGL2 fallback; Canvas 2D / OffscreenCanvas in a Worker; SVG filter chains (displacement, turbulence, morphology).
- **Data:** virtual scrolling (TanStack Virtual for complex cases); Canvas/WebGL charts (deck.gl); morphing between chart states (D3 `transition()` or View Transitions).
- **Properties:** `@property` to interpolate gradients and typed values; Web Animations API for composable, cancellable sequences.
- **Performance:** Web Workers, OffscreenCanvas, WASM for heavy computation.
- **Device:** Web Audio (needs a user gesture); orientation and other device APIs only with permission.

## Implement with discipline

Every technique degrades gracefully; the experience without it must still be good.

```css
@supports (animation-timeline: scroll()) {
  .hero { animation-timeline: scroll(); }
}
```

```javascript
if ('gpu' in navigator) { /* WebGPU */ }
else if (canvas.getContext('webgl2')) { /* WebGL2 fallback */ }
/* CSS-only fallback must still look good */
```

- Lazy-initialize WebGL contexts and WASM modules near the viewport; pause off-screen rendering.
- Verify in the browser, not from code: check timing, easing and smoothness on a mid-range device, batch fixes between looks, refine until it holds.

**Never:**
- Ship effects that jank on mid-range devices.
- Use bleeding-edge APIs without a working fallback.
- Add sound without explicit opt-in.
- Use technical ambition to mask weak fundamentals; fix those first with other commands.
- Layer competing extraordinary moments.

## Verify

- **Wow:** someone who has not seen it reacts.
- **Removal:** taking it away diminishes the experience.
- **Device:** still smooth on a phone, tablet and low-end laptop.
- **Context:** it fits this brand and audience.
