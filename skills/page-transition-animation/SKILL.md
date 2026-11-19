---
name: page-transition-animation
description: Use when animating page or route transitions, adding a crossfade between pages, using the View Transitions API (startViewTransition, ::view-transition-old/new, view-transition-name, @view-transition), animating route changes in Next.js App Router (template.tsx, next-view-transitions), or when AnimatePresence exit doesn't fire on navigation / the old page disappears instantly / the exiting page flashes the new route's content. Not for swapping views inside one component; use choreograph or micro-interaction. Not for GSAP Flip layout moves; use gsap-web.
version: 0.1.0
---

# Page Transition Animation

## Overview

In the Next.js App Router, navigation unmounts the old route and mounts the new one almost immediately, so `AnimatePresence` exits never fire: an exit needs the exiting element to stay mounted under a *persistent* `AnimatePresence` long enough to animate. Two fixes: pathname-keyed `AnimatePresence` with **FrozenRouter**, or the **View Transitions API** (native / `next-view-transitions`).

## When to Use

- Adding page enter/exit transitions to an App Router app
- A Framer Motion `exit` does nothing on route change; the old page vanishes instead of animating out
- Choosing between Framer Motion and View Transitions
- Shared-element transitions across pages

`AnimatePresence` detects removal of a *direct keyed child*. On navigation:

1. The wrapper must persist; if it lives in a component that unmounts, nothing runs the exit.
2. The child's `key` must change per route so it sees "old removed, new added".
3. The outgoing subtree must keep rendering its old content, but the router has already swapped context, so it would render the *new* page. FrozenRouter fixes this.

| Choose | When |
|---|---|
| View Transitions | Simple cross-page fades/morphs, shared elements, minimal JS |
| Framer Motion + FrozenRouter | Fine-grained, orchestrated, interruptible or staggered exits |

## Core Pattern

| Before | After |
|---|---|
| `AnimatePresence` inside the page | In `app/template.tsx` (remounts per navigation; `layout.tsx` persists and never remounts) |
| No key | `key={pathname}` from `usePathname()` |
| Exiting page shows new route content | Wrap children in `FrozenRouter` |
| `document.startViewTransition(...)` unguarded | `if (document.startViewTransition)` fallback |

## Quick Reference

| Need | Approach |
|---|---|
| Per-route enter animation | `app/template.tsx` |
| Exit animation on nav | keyed `AnimatePresence mode="wait"` + FrozenRouter |
| Outgoing page shows old content | FrozenRouter (snapshot `LayoutRouterContext`) |
| Detect route change | `usePathname()` as the `key` |
| Simple cross-page fade/morph | View Transitions API / next-view-transitions |
| Shared element transition | `view-transition-name` CSS |
| Skip first-load animation | `initial={false}` |
| Overlap/crossfade instead of wait | default mode |

## Implementation

### A: template.tsx + keyed AnimatePresence + FrozenRouter

```tsx
// app/template.tsx
'use client';
import { AnimatePresence } from 'framer-motion';
import { usePathname } from 'next/navigation';
import { FrozenRouter } from './frozen-router';
import { PageTransition } from './page-transition';

export default function Template({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  return (
    <AnimatePresence mode="wait" initial={false}>
      <PageTransition key={pathname}>
        <FrozenRouter>{children}</FrozenRouter>
      </PageTransition>
    </AnimatePresence>
  );
}
```

```tsx
// app/page-transition.tsx
'use client';
import { motion } from 'framer-motion';

export function PageTransition({ children }: { children: React.ReactNode }) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 12 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, y: -12 }}
      transition={{ duration: 0.3, ease: [0.22, 1, 0.36, 1] }}
    >
      {children}
    </motion.div>
  );
}
```

```tsx
// app/frozen-router.tsx
'use client';
import { useContext, useRef } from 'react';
import {
  LayoutRouterContext,
} from 'next/dist/shared/lib/app-router-context.shared-runtime';

// Freezes the router context so the exiting page keeps rendering its
// OWN content during the exit animation instead of the next route's.
export function FrozenRouter({ children }: { children: React.ReactNode }) {
  const context = useContext(LayoutRouterContext ?? {});
  const frozen = useRef(context).current;

  return (
    <LayoutRouterContext.Provider value={frozen}>
      {children}
    </LayoutRouterContext.Provider>
  );
}
```

- `mode="wait"` finishes the exit before mounting the new page.
- `initial={false}` skips the enter animation on first load (optional).
- `LayoutRouterContext` is a Next.js internal; its import path can change between versions — the first thing to fix after an upgrade.

### B: native View Transitions API

The browser captures before/after snapshots; no per-element exit components.

```css
/* globals.css */
@view-transition { navigation: auto; } /* opt MPA-style in (where supported) */

::view-transition-old(root) { animation: fade 0.25s both reverse; }
::view-transition-new(root) { animation: fade 0.25s both; }
@keyframes fade { from { opacity: 0; } to { opacity: 1; } }
```

SPA-style navigation:

```ts
if (document.startViewTransition) {
  document.startViewTransition(() => router.push(href));
} else {
  router.push(href);
}
```

`next-view-transitions` wires this into App Router client navigation:

```tsx
// app/layout.tsx
import { ViewTransitions } from 'next-view-transitions';
export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <ViewTransitions>
      <html lang="en"><body>{children}</body></html>
    </ViewTransitions>
  );
}
```

```tsx
// use the library's Link instead of next/link
import { Link } from 'next-view-transitions';
<Link href="/about">About</Link>;
```

Browser support is uneven; always keep the guard.

### Debug checklist (exit still won't fire)

1. **Wrapper stays mounted** — `template.tsx` or a layout-level client component, not the unmounting page.
2. **Key changes per route** — `key={pathname}`; no key or an unchanging key → no exit.
3. **Direct motion descendant** — the `exit` element is a `motion.*` child of `AnimatePresence`; a non-motion wrapper between can block detection.
4. **`mode="wait"`** if old and new must not overlap; otherwise both render and may jump.
5. **FrozenRouter present** if the outgoing page flashes the new route's content.
6. **`'use client'`** on every file using AnimatePresence/usePathname/motion; server components can't.
7. **One keyed child** under `mode="wait"`.

### Standalone prototype

To prove the transition shape (curve, direction, crossfade) before wiring the router, ship one HTML file: two view stubs and a toggle, animated with `motion`/React from CDN in an inline module or `document.startViewTransition` + `::view-transition-*` CSS. Don't stand up Next to eyeball a fade.

Pin a phase with `?view=b` (destination) or `?phase=exit` (outgoing tree mid-animation):

```html
<script>
  const p = new URLSearchParams(location.search);
  document.documentElement.dataset.view = p.get("view") || "a";   // CSS/React keys off this
  // Framer Motion: set the controlled key/route from ?view; for mode="wait" the resolved end is the new page
  // View Transitions: screenshot the END state (snapshots are transient); or pause via emulate slow animations
  window.__ready = true;
</script>
```

```bash
bunx playwright screenshot --wait-for-timeout=500 "file://$PWD/transition.html?view=b" dest.png
```

Screenshot `?view=a`, `?phase=exit`, `?view=b` and confirm: no console errors, `startViewTransition` guarded; exit actually runs, direction matches the brief; no content flash, double mount or FOUC; reduced motion drops slide to a short crossfade; entrances ease-out, exits ease-in, ~0.2–0.4s.

### References

- `references/full-examples.md` — read for directional/slide transitions, shared-element View Transitions with `view-transition-name`, a non-`mode="wait"` crossfade, `loading.tsx` loading-state transitions, and a full App Router folder layout.

## Common Mistakes

| Mistake | Fix |
|---|---|
| Per-route animation in `layout.tsx` | `template.tsx` |
| No FrozenRouter | Exiting page flashes new content or skips exit |
| No `key={pathname}` | Exit never triggers |
| Slow exits under `mode="wait"` | Navigation feels laggy; keep ~0.2–0.4s |
| Unguarded `startViewTransition` | Feature-detect and fall back |
| Missing `'use client'` | Add to every transition file |
