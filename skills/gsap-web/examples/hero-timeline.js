/**
 * hero-timeline.js — complete, runnable GSAP hero entrance.
 *
 * Markup expected:
 *   <section class="hero">
 *     <p class="hero__eyebrow">EYEBROW</p>
 *     <h1 class="hero__title">Big bold headline that wraps</h1>
 *     <p class="hero__sub">Supporting copy.</p>
 *     <div class="hero__actions"><a class="btn">Primary</a><a class="btn btn--ghost">Secondary</a></div>
 *     <img class="hero__art" src="art.svg" alt="" />
 *   </section>
 *
 * CSS prerequisites:
 *   .hero__title .line { overflow: hidden; }   // split line wrapper masks the reveal
 *   .hero__eyebrow, .hero__title, .hero__sub, .hero__actions, .hero__art { visibility: hidden; }
 *                                              // no flash before fonts load; JS reveals them
 *
 * Install:  bun add gsap
 */

import gsap from "gsap";
import { SplitText } from "gsap/SplitText";

gsap.registerPlugin(SplitText);

export function playHeroIntro(root = document) {
  const reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  const q = gsap.utils.selector(root);

  // Reduced motion: no movement, a short opacity fade only.
  if (reduceMotion) {
    return Promise.resolve(
      gsap.fromTo(
        q(".hero__eyebrow, .hero__title, .hero__sub, .hero__actions, .hero__art"),
        { autoAlpha: 0 },
        { autoAlpha: 1, duration: 0.2, ease: "power4.out" },
      ),
    );
  }

  // Wait for fonts so SplitText computes correct line breaks.
  return document.fonts.ready.then(() => {
    const titleEl = q(".hero__title")[0];
    const split = new SplitText(titleEl, {
      type: "lines",
      linesClass: "line",
      autoSplit: true, // GSAP 3.13+: re-split on resize/font swap
    });

    // Containers whose children animate become visible now; the rest fade in via
    // .from(autoAlpha: 0) up to the CSS opacity (1). Do not gsap.set them to
    // autoAlpha 0 first: .from() would then tween 0 → 0 and they never appear.
    gsap.set([titleEl, ...q(".hero__actions")], { autoAlpha: 1 });

    const tl = gsap.timeline({
      defaults: { ease: "power3.out", duration: 0.8 },
      onComplete: () => split.revert(), // restore clean DOM once done (optional)
    });

    tl.from(q(".hero__eyebrow"), { y: 16, autoAlpha: 0, duration: 0.5 })
      .from(split.lines, { yPercent: 110, stagger: 0.06, duration: 0.9, ease: "power4.out" }, "-=0.2")
      .from(q(".hero__sub"), { y: 20, autoAlpha: 0 }, "-=0.6")
      .from(q(".hero__actions .btn"), { y: 12, autoAlpha: 0, stagger: 0.06, duration: 0.5 }, "-=0.4")
      .from(q(".hero__art"), { scale: 0.92, autoAlpha: 0, ease: "back.out(1.4)", duration: 1.1 }, "<0.1");

    return tl;
  });
}

// Auto-run on DOM ready when imported directly in a page.
if (typeof window !== "undefined" && document.querySelector(".hero")) {
  if (document.readyState !== "loading") playHeroIntro();
  else document.addEventListener("DOMContentLoaded", () => playHeroIntro());
}
