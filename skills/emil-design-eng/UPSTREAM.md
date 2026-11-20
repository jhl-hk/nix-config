# Upstream

| | |
|---|---|
| Source | https://github.com/emilkowalski/skills — `skills/emil-design-eng/` |
| Commit | `f7ce8c02d6e3c8f0d980a44c57bcc41a40254349` |
| License | MIT |

## Local changes

- Description rewritten to triggers plus neighbour boundaries.
- Removed the canned initial response, persona and philosophy essays; added Overview and When to Use.
- Removed the wrong-format example in Review Format.
- Gesture, accessibility and stagger sections condensed to their values with pointers to apple-design, accessible-animation, mobile-native, choreograph.
- Review Checklist renamed Common Mistakes.
- Animation Decision Framework and Spring Animations (frequency gate, purposes, easing tree, curve tokens, duration table, perceived performance, spring configs) replaced by `**REQUIRED BACKGROUND:** animate` plus the component-only facts; the `useSpring` example converted from stiffness 100 / damping 10 to `{ duration: 0.5, bounce: 0.5 }`, keeping its bounce (damping ratio 0.5 → bounce 0.5, animate's conversion rule; an earlier pass had flattened it to 0.25), and imported from `motion/react` instead of `framer-motion`.
- `--swipe-amount` CSS-variable section reduced to one rule with a pointer to animation-performance.
- Common Mistakes: duration row allows modals/drawers past 300ms; exit-speed row uses ~20% faster exits and the hold-to-confirm 2s/200ms example.
- Anecdotes cut, rules kept: Sonner/Vaul as users of `translateY(100%)`, the Vercel dashboard tab story, "13M+ weekly npm downloads". The "unseen details compound" line after popovers cut (repeats Overview).
- Sonner Principles renamed Component Principles and cut to good defaults and invisible edge cases; dropped developer-experience setup, naming and documentation-site points (not about component feel) and "transitions, not keyframes" (stated in its own section).
- Hold-to-delete overlay CSS kept once (Asymmetric enter/exit timing); the copy in the clip-path inset block removed, the prose pattern points to it.
- "Review your work the next day" and Debugging Animations (slow motion, frame-by-frame, real devices) replaced by a Debugging Feel pointer to improve-animations AUDIT.md "Debugging feel" and mobile-native.
- Common Mistakes: dropped the keyframes-on-rapid-triggers row (stated in "Use CSS transitions over keyframes").
- Built-in `ease-out` in code and fixes replaced by `var(--ease-out)` (animate's token), matching animate's ban on built-in curves for deliberate motion.
- Curve tokens in code carry a literal fallback (copy-paste safe without animate's :root tokens).
- Tooltip, blur-crossfade and `@starting-style` sections cut to their rule plus a pointer to animate RECIPES (Tooltip, Masking a crossfade that won't settle, Toast), which carries the same CSS.
- Component Building Principles renamed Core Pattern; Motion Values renamed Quick Reference and moved after it (README C.1 shape).
