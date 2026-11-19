Find the actual bottleneck for this interface, fix it, measure again. Do not optimize what is not slow.

## Assess

1. **Measure:** Core Web Vitals (LCP, INP, CLS), FCP, TBT, bundle sizes (JS, CSS, images), frame rate, memory, CPU, request count and waterfall.
2. **Bottleneck:** what is slow (load, interaction, animation), what causes it, how bad, and who is affected (mobile, slow networks).

Measure before and after, on real devices and throttled networks. Desktop Chrome on fast Wi-Fi is not representative.

## Loading

**Images**
- AVIF/WebP, sized to display, lazy below the fold, `srcset`/`<picture>`, 80–85% quality, CDN.
- Astro: use `astro:assets` (`<Image />` / `<Picture />`) for sizing, formats and dimensions.

```html
<img src="hero.webp"
  srcset="hero-400.webp 400w, hero-800.webp 800w, hero-1200.webp 1200w"
  sizes="(max-width: 400px) 400px, (max-width: 800px) 800px, 1200px"
  width="1200" height="675" alt="…" />
```

**JavaScript**
- Code split by route and component, tree shake, drop unused dependencies, dynamic `import()` for heavy components.
- **Astro:** pages ship zero JS by default. Hydrate islands only where interaction is needed, with the latest directive that works: `client:visible` (below the fold), `client:idle` (non-urgent), `client:load` (immediately interactive). Prefer static markup over an island.
- **Vue:** `defineAsyncComponent(() => import('./HeavyChart.vue'))`; `shallowRef` for large objects that are replaced, not mutated; `v-memo` on large `v-for` lists that rarely change.
- **React only:** `const HeavyChart = lazy(() => import('./HeavyChart'))`; `memo()` for expensive components; `useMemo`/`useCallback` for expensive computations and stable props; React DevTools Profiler.

**CSS**
- Remove unused CSS (Tailwind already purges by content scan), inline critical CSS, `contain` on independent regions.

**Fonts**
- `font-display: swap` or `optional`, subset, preload critical faces, limit weights.

```css
@font-face {
  font-family: 'CustomFont';
  src: url('/fonts/custom.woff2') format('woff2');
  font-display: swap;
  unicode-range: U+0020-007F; /* Basic Latin */
}
```

**Strategy**
- async/defer non-critical scripts, preload critical assets, prefetch likely next pages, service worker caching, HTTP/2 or HTTP/3.

## Rendering

Batch DOM reads before writes:

```javascript
// Bad: interleaved read/write forces a reflow per element
elements.forEach(el => { el.style.height = el.offsetHeight * 2 + 'px'; });
// Good
const heights = elements.map(el => el.offsetHeight);
elements.forEach((el, i) => { el.style.height = heights[i] * 2 + 'px'; });
```

- Flatter, smaller DOM; `content-visibility: auto` on long sections; virtualize very long lists with TanStack Virtual.
- Use `IntersectionObserver` for lazy work tied to the viewport, not scroll handlers.
- Animation jank, compositing, `will-change` and frame budgets: `animation-performance` skill.

## Network

- Fewer requests: SVG sprites, inline small critical assets, remove unused third-party scripts.
- APIs: paginate, request only needed fields, brotli/gzip, caching headers, CDN.
- Slow connections: adapt via `navigator.connection`, optimistic UI, request prioritization, progressive enhancement.

## Core Web Vitals

- **LCP < 2.5s:** optimize the hero image, inline critical CSS, preload key resources, server-render.
- **INP < 200ms:** break up long tasks, defer non-critical JS, move heavy work to Web Workers.
- **CLS < 0.1:** set dimensions or `aspect-ratio` on media, reserve space for embeds, never inject content above existing content.

## Tools

- Chrome DevTools (Lighthouse, Performance panel), WebPageTest, Chrome UX Report.
- Bundle: `rollup-plugin-visualizer` / `vite-bundle-visualizer`; `astro build` output sizes.
- Field monitoring: Sentry, Datadog or similar.

**Avoid:** optimizing without measuring, trading away accessibility or functionality, `will-change` everywhere, lazy-loading above-the-fold content, micro-optimizations before the biggest bottleneck, ignoring low-end mobile.

## Verify

- Before/after metrics and bundle sizes.
- Low-end Android and throttled network.
- No functional regressions.
- It feels faster.
