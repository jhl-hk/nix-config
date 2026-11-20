> **Additional context needed**: performance constraints.

Motion explains state, relationship and hierarchy, or carries the one authored moment the surface has earned. Effect craft lives in other skills: `animate` (building motion), `choreograph` (stagger and sequencing), `accessible-animation` (reduced motion), `animation-performance` (jank). This file holds what is specific to impeccable.

## Visitor mode

- **Persuade + Experience:** one rehearsed focal sequence, not repeated section reveals.
- **Operate + Read:** feedback, state and continuity only. No page-load choreography.
- **Native (`ios` / `android` / `adaptive`):** follow the Motion section of [ios.md](ios.md) or [android.md](android.md). The web rules below do not apply.

## Find the job

Inspect the existing motion language, states, target devices and performance budget. Animate only where motion acknowledges an action, makes a state change or spatial relationship legible, preserves continuity, directs attention at a meaningful moment, or embodies the visual world. Do not animate a static area because it exists.

## Motion thesis

Write before implementing:

- **Focal moment:** the one sequence that deserves authorship, if any. It comes from this product and surface concept. A generic fade-and-rise, hover lift, parallax layer or scroll reveal is not a thesis.
- **Continuity:** state, layout or navigation changes that need explanation.
- **Feedback:** controls and outcomes that need acknowledgment.
- **Budget:** which effects are expensive and how often they run.

Choose the material for its meaning: shared-element or FLIP for continuity, bounded blur or shadow for depth, masks and clip paths for reveal, colour or texture for energy. One strong material idea is enough; do not stack techniques.

## Timing and easing

Durations, curves and springs come from the animate skill (**REQUIRED BACKGROUND:** animate). A deliberately authored focal entrance may run 500–800 ms.

- Content is visible in the default state, so a failed script hides nothing.
- Every web animation has a `prefers-reduced-motion` path that reduces movement but keeps meaningful feedback. Detail: `accessible-animation` skill.
- Nonessential loops stop when offscreen or hidden.

## Implement

Use the stack's existing tools (CSS, Web Animations API, View Transitions, the project's motion library). Do not add a dependency for an effect the stack expresses cleanly. Scroll-driven motion only when the scroll relationship carries meaning. In live mode, expose the motion axes (duration, distance, intensity) as parameters per [live.md](live.md) section 7.

## Verify

- The focal motion is specific to the world and surface.
- Every supporting animation explains feedback, state or relationship.
- Interruption and repeated use behave.
- The reduced-motion path keeps feedback legible.
- Expensive effects stay smooth on the target device.
