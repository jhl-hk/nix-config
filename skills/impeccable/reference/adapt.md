> **Additional context needed**: target platforms/devices and usage contexts.

Adapt an existing design to another screen size, device, input method or medium. Adaptation rethinks the experience for the new context; it does not scale pixels.

**Web only** (mobile web included). Native platforms (`ios` / `android` / `adaptive`) use [adapt.native.md](adapt.native.md); switch now if the project is native. Mobile-web quirks (safe areas and the notch, `100vh`, input zoom, tap highlight, PWA chrome) live in the `mobile-native` skill.

## Canonical values

- **Breakpoints:** 640 / 768 / 1024 / 1280px (Tailwind `sm`/`md`/`lg`/`xl`), mobile-first with `min-width`. Add a content-driven breakpoint only where the design actually breaks; use `clamp()` and container queries for fluid values in between.
- **Touch targets (web):** 44×44 CSS px minimum, with spacing between adjacent targets. WCAG 2.5.8 (AA) sets an absolute floor of 24×24px; treat 44 as the working minimum. Native sizes: [ios.md](ios.md), [android.md](android.md).
- **Body text:** 16px minimum on mobile.

## Assess

1. **Source context:** what it was designed for and which assumptions it made (large screen, mouse, fast network).
2. **Target context:** device (phone, tablet, desktop, TV, print, email), input (touch, mouse, keyboard), orientation, connection, usage (on the go vs focused), platform expectations.
3. **What breaks:** what won't fit, what won't work (hover on touch, tiny targets), what is inappropriate for the platform.

## Strategy by target

**Desktop → mobile**
- Single column, vertical stacking, full-width components.
- Bottom navigation or a drawer; sticky headers for context; simpler navigation.
- Bottom sheets instead of dropdowns; controls within thumb reach; no hover-dependent interaction.
- Progressive disclosure; secondary content in tabs or accordions; shorter copy.
- Tables become cards (`display: block` rows with `data-label`); `<details>/<summary>` for collapsible content.

**Tablet**
- Two columns, master-detail, side panels; adapt to orientation.
- Support touch and pointer; denser than phone at the same target size.

**Mobile → desktop**
- Multi-column, persistent side navigation, several panels at once, `max-width` so content does not stretch to 4K.
- Hover for extra information, keyboard shortcuts, context menus, drag and drop, Shift/Cmd multi-select.
- More information upfront, wider tables, richer visualizations.

**Print**
- Logical page breaks; remove navigation and interactive elements; limited colour; binding margins.
- Expand hidden content and full URLs; page numbers, headers, print date and title; print-friendly charts.

**Email**
- 600px max, single column, inline CSS, table layout.
- Large button CTAs, no hover, deep links to the app for complex tasks.

## Implement

- Grid/Flexbox reflow, container queries, `clamp()`, media queries.
- Detect input, not screen size:

```css
@media (pointer: coarse) { .button { padding: 12px 20px; } }
@media (hover: hover)   { .card:hover { transform: translateY(-2px); } }
```

  Never put functionality behind hover.
- `display: none` still downloads; lazy-load off-screen content.
- Responsive images: `srcset` with `w` descriptors plus `sizes`; `<picture>` with `media` sources for art direction (different crops). In Astro use `astro:assets`.

```html
<img src="hero-800.jpg" srcset="hero-400.jpg 400w, hero-800.jpg 800w, hero-1200.jpg 1200w"
  sizes="(max-width: 768px) 100vw, 50vw" alt="…">
```

**Avoid:** hiding core functionality on mobile, assuming desktop means powerful, different information architecture per context, ignoring landscape or touch on desktop, device detection instead of feature detection, separate mobile and desktop codebases.

## Verify

- Real devices: at least one iPhone, one Android (a cheap one exposes performance issues), a tablet if relevant. DevTools emulation misses real touch, CPU, latency, font rendering and browser chrome.
- Portrait and landscape; Safari, Chrome, Firefox; touch, mouse and keyboard; 320px and 4K; throttled network.

**Custom controls** (sliders, drag surfaces, scrollable control strips) can pass every width check and still refuse to drag on iOS. Exercise each one in the same batched round:

- **Primary gesture:** tap it, then drag it with the target input; the drag must complete, not just start.
- **Scroll across it:** a swipe along the page's scroll axis across the control scrolls the page without activating it; a drag that starts on the control along its axis moves the control, not the page. Neither failure throws an error; try both.
- **Evidence:** say what produced it (emulated viewport, synthesized touch, which engine — Chromium is not Safari — or a physical device). Screenshots and resized viewports verify layout, never a gesture. Name what stayed untested; unreachable hardware is a reported gap, not a blocker.
