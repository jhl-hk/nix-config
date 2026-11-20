# Standalone screenshot harness

Read when a demo, prototype or deliverable must be checked by screenshot rather than by eye: freezing a frame, forcing a state, or capturing the reduced-motion path. Each skill keeps its own list of what to screenshot and what to confirm.

## File shape

One self-contained HTML file that opens in a browser. No bundler, no framework app stood up to eyeball a fade.

- Pure CSS as-is.
- React + `motion` from `esm.sh` in one inline `<script type="module">`.
- GSAP + plugins from CDN, all motion on **one master timeline** `tl` in one inline `<script>`.
- SVG inline in the DOM with one driver (CSS `@keyframes`, GSAP or SMIL).
- View transitions: two view stubs and a toggle, driven by `motion` or `document.startViewTransition` + `::view-transition-*` CSS.

End the script with `window.__ready = true;` once motion is built.

## Query parameters

Read once at the top: `const q = new URLSearchParams(location.search);`

| Param | Freezes / forces | Code |
|---|---|---|
| `?t=N` CSS `@keyframes` | One element at N seconds | `el.style.animationDelay = (-N) + "s"; el.style.animationPlayState = "paused";` |
| `?t=N` CSS animations and transitions, WAAPI | Every running animation at N seconds | `document.getAnimations().forEach(a => { a.currentTime = N * 1000; a.pause(); });` (or one kept `anim`: `anim.pause(); anim.currentTime = N * 1000;`) |
| `?t=N` GSAP timeline | The master timeline at N seconds | `tl.pause(); tl.seek(N);` and `console.log("duration", tl.duration());` so the end frame is known |
| `?t=N` SVG SMIL | The SVG's own clock at N seconds | `svg.pauseAnimations(); svg.setCurrentTime(N);` (optional-chain `svg?.pauseAnimations?.()` when the SVG may be absent) |
| `?state=<name>` | A settled state (idle / hover / pressed / open) | `document.documentElement.dataset.state = s;` and CSS keys off `:root[data-state="hover"]`; Framer Motion: set the controlled prop from it (`useState(s === "open")`) |
| `?view=a\|b` | Source or destination view | `document.documentElement.dataset.view = q.get("view") \|\| "a";`; Framer Motion: set the controlled key/route from it; under `mode="wait"` the resolved end is the new page |
| `?phase=exit` | Outgoing tree mid-animation | Combine with a `?t=N` freeze on the exit animation |
| `?reduce=1` | The JS reduced-motion path | `const reduce = q.get("reduce") === "1" \|\| matchMedia("(prefers-reduced-motion: reduce)").matches;` then build motion conditionally; for CSS-only fallbacks, toggle a class that mirrors the media query |

View Transitions snapshots are transient: screenshot the end state, or pause mid-flight with DevTools' emulate slow animations.

Combined skeleton:

```html
<script>
  const q = new URLSearchParams(location.search);
  const s = q.get("state");
  if (s) document.documentElement.dataset.state = s;
  const reduce = q.get("reduce") === "1"
    || window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  // ... build motion (conditionally on `reduce`); GSAP: master timeline `tl` ...
  const t = q.get("t");
  if (t !== null) {
    const N = parseFloat(t);
    document.getAnimations().forEach(a => { a.currentTime = N * 1000; a.pause(); }); // CSS + WAAPI
    // GSAP: tl.pause(); tl.seek(N);
    // SMIL: const svg = document.querySelector("svg"); svg?.pauseAnimations?.(); svg?.setCurrentTime?.(N);
  }
  window.__ready = true;
</script>
```

## Screenshot

```bash
bunx playwright screenshot --wait-for-timeout=500 "file://$PWD/anim.html?t=0.3" frame.png
bunx playwright screenshot --wait-for-timeout=400 "file://$PWD/demo.html?state=open" open.png
bunx playwright screenshot --wait-for-timeout=500 "file://$PWD/transition.html?view=b" dest.png
bunx playwright screenshot --wait-for-timeout=500 "file://$PWD/demo.html?t=0.6&reduce=1" reduced.png
```

The CLI has no reduced-motion option. To emulate the media feature for the CSS layer, use a script:

```js
// bun reduced.mjs: run it outside any node_modules tree (bun auto-installs playwright), or `bun add -d playwright` first
import { chromium } from "playwright";
const browser = await chromium.launch();
const page = await browser.newPage();
await page.emulateMedia({ reducedMotion: "reduce" });
page.on("console", (m) => m.type() === "error" && console.log("console error:", m.text()));
await page.goto(`file://${process.cwd()}/demo.html?t=0.6`);
await page.waitForTimeout(500);
await page.screenshot({ path: "reduced-css.png" });
await browser.close();
```

- Timelines: `?t=0`, `?t=<dur/2>`, `?t=<dur>` (start, mid, end).
- Reduced motion: screenshot **both** paths; `emulateMedia({ reducedMotion: "reduce" })` covers the CSS layer, `?reduce=1` forces the JS path.
- A page over `file://` cannot import local module files (CORS); CDN imports such as esm.sh still load. For local modules, serve the directory over HTTP (`bunx serve .`).
- Always confirm no console errors and that every CDN import resolves.
- Rendering cost: capture a CDP trace and assert no `Layout`/`Paint` events fire during the animation window.
