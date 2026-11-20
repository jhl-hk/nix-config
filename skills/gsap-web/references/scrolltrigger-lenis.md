# ScrollTrigger + Lenis / Locomotive smooth-scroll sync

Jitter, marker drift, broken pins and flipped scroll all come from two loops ticking independently. The canonical one-loop wiring, the seconds→milliseconds conversion, teardown and the symptom table are in SKILL.md › Lenis smooth scroll + ScrollTrigger; this file holds the variants.

## Locomotive Scroll v4 variant

Locomotive v4 needs `scrollerProxy` because it scrolls an inner element, not `window`. Same principle (one loop, update ScrollTrigger on scroll); the proxy maps coordinates. Locomotive v5 is built on Lenis: follow the Lenis wiring instead.

```js
const locoScroll = new LocomotiveScroll({
  el: document.querySelector('[data-scroll-container]'),
  smooth: true,
});

locoScroll.on('scroll', ScrollTrigger.update);

ScrollTrigger.scrollerProxy('[data-scroll-container]', {
  scrollTop(value) {
    return arguments.length
      ? locoScroll.scrollTo(value, { duration: 0, disableLerp: true })
      : locoScroll.scroll.instance.scroll.y;
  },
  getBoundingClientRect() {
    return { top: 0, left: 0, width: innerWidth, height: innerHeight };
  },
  pinType: document.querySelector('[data-scroll-container]').style.transform
    ? 'transform' : 'fixed',
});

ScrollTrigger.addEventListener('refresh', () => locoScroll.update());
ScrollTrigger.refresh();
```

Every ScrollTrigger then needs `scroller: '[data-scroll-container]'`. Lenis scrolls the real document, so it needs no `scrollerProxy`, and pinned triggers work without one.

## Refresh and resize

On dynamic content/resize, call `ScrollTrigger.refresh()` after layout settles. With Lenis, also call `lenis.resize()` if the container size changes.

## Excluding regions from smooth scroll

```html
<div class="code-block" data-lenis-prevent>…natively scrollable…</div>
```

`data-lenis-prevent` on a scrollable element (modal, code block) makes Lenis ignore wheel/touch there, so inner scrolling works normally while the page stays smooth.

## Anchor links with smooth scroll

Native `<a href="#section">` jumps bypass Lenis (instant jump, then Lenis fights it). Route anchors through `lenis.scrollTo`:

```js
document.querySelectorAll('a[href^="#"]').forEach((a) => {
  a.addEventListener('click', (e) => {
    const id = a.getAttribute('href');
    if (id.length > 1) {
      e.preventDefault();
      lenis.scrollTo(id, { offset: 0 });  // accepts selector, element, or number
    }
  });
});
```

If a sticky header overlaps the target, pass a negative offset or an offset callback:

```js
lenis.scrollTo(targetEl, { offset: -80 }); // 80px sticky header
```

## Reduced-motion gate

Under `prefers-reduced-motion`, do not instantiate Lenis (or stop it) and let ScrollTrigger run on native scroll:

```js
const prefersReduced = matchMedia('(prefers-reduced-motion: reduce)').matches;
let lenis;
if (!prefersReduced) {
  // Lenis wiring from SKILL.md
}
// ScrollTrigger animations are defined normally and work with or without Lenis
```

## React integration (useGSAP)

```jsx
'use client';
import { useRef } from 'react';
import Lenis from 'lenis';
import gsap from 'gsap';
import { ScrollTrigger } from 'gsap/ScrollTrigger';
import { useGSAP } from '@gsap/react';

gsap.registerPlugin(ScrollTrigger, useGSAP);

export default function ScrollSection() {
  const root = useRef(null);

  useGSAP(() => {
    const prefersReduced = matchMedia('(prefers-reduced-motion: reduce)').matches;

    let lenis;
    let update;
    if (!prefersReduced) {
      lenis = new Lenis({ duration: 1.2, smoothWheel: true });
      lenis.on('scroll', ScrollTrigger.update);
      update = (time) => lenis.raf(time * 1000);
      gsap.ticker.add(update);
      gsap.ticker.lagSmoothing(0);
    }

    gsap.to('.panel', {
      xPercent: -100,
      ease: 'none',
      scrollTrigger: {
        trigger: '.panel',
        start: 'top top',
        end: '+=1500',
        scrub: true,
        pin: true,
        // markers: true, // enable while debugging
      },
    });

    return () => {
      if (lenis) {
        gsap.ticker.remove(update);
        lenis.destroy();
      }
    };
  }, { scope: root });

  return (
    <div ref={root}>
      <section className="panel">…</section>
    </div>
  );
}
```

`useGSAP` auto-reverts GSAP tweens/ScrollTriggers created in its scope on unmount; the returned function additionally tears down Lenis and the ticker callback so nothing leaks across navigations.

Without `@gsap/react`: the same setup in `useEffect(() => { … }, [])`, with the ScrollTrigger code inside `const ctx = gsap.context(() => { … })` and `ctx.revert()` added to the returned teardown after `gsap.ticker.remove(update)` and `lenis.destroy()`.
