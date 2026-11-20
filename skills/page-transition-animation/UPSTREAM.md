# Upstream

| | |
|---|---|
| Source | https://github.com/iart-ai/web-animation-skills — `skills/page-transition-animation/` |
| Commit | `ed3a045192679b24d32090ee7a983871311ababd` |
| License | MIT |

## Local changes

- Description rewritten to triggers plus boundaries (choreograph, micro-interaction, gsap-web); View Transitions API terms added as triggers.
- Body restructured to the standard shape; framework choice as a table; Gotchas merged into Common Mistakes; Deliver & verify condensed.
- Deleted the empty `README.md`.
- Removed the dangling "Packaged helper (`scripts/`)" note; no `scripts/` directory ships with this skill.
- `npx playwright` examples changed to `bunx playwright`.
- Exits changed from ease-in to ease-out, ~20% faster than entrances (animate owns easing). Framer `ease: [0.22, 1, 0.36, 1]` → animate's `--ease-out` `[0.23, 1, 0.32, 1]` in SKILL.md and `references/full-examples.md`.
- Standalone prototype harness code replaced by a pointer to animate `references/standalone-harness.md` (Framer Motion controlled key, `mode="wait"` end state and View Transitions notes moved there); the `?view=` / `?phase=exit` check list stays.
- Both exit examples (SKILL.md `PageTransition`, `references/full-examples.md` directional slide) carry their own exit transition at 0.24s, ~20% faster than the 0.3s entrance.
- `framer-motion` imports → `motion/react` in SKILL.md and `references/full-examples.md`.
- Section A marked Next.js App Router only, `next-view-transitions` marked Next.js only; section B gains an Astro note (`<ClientRouter />` from `astro:transitions`, `transition:name`, `transition:animate`, `transition:persist`, built-in fallback, reduced motion disables its animations); description gains the Astro triggers.
- Browser support: "uneven" replaced by same-document view transitions Baseline since October 2025 (Firefox 144), cross-document not Baseline (Chromium 126+, Safari 18.2+), in SKILL.md and the full-examples decision table.
- Core Pattern dropped the `key={pathname}` and FrozenRouter rows; Common Mistakes dropped the `layout.tsx`, FrozenRouter, key, unguarded `startViewTransition` and `'use client'` rows (all in the Debug checklist or Core Pattern).
- `references/full-examples.md`: reduced-motion path keeps a short opacity crossfade (enter 0.15s, exit 0.12s) and drops only the slide, instead of `duration: 0` / exit `opacity: 1` / View Transitions `animation: none`; "pin awareness in any upgrade checklist" filler cut; Next.js-only scope line added; iart.ai footer removed.
