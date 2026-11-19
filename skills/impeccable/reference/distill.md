Strip a design to its essence. Remove what does not earn its place: redundant elements, repeated information, decorative noise, cosmetic complexity.

## Assess

1. **Complexity sources:** competing buttons, redundant information, purposeless variation in colour, type and style, everything visible at once, borders and backgrounds with no job, unclear hierarchy, too many options or paths.
2. **The essence:** the one primary user goal, what is necessary versus nice-to-have, what can be removed, hidden or combined.

If any of this is unclear from the codebase, ask the user and wait.

Simplicity removes obstacles between users and their goals, not features.

## Plan

Name the core purpose, the elements essential to it, what can wait behind progressive disclosure, and what can be merged.

## Simplify

**Information architecture**
- Remove secondary actions and redundant information; say each thing once.
- Progressive disclosure behind clear entry points (accordions, step-through flows).
- Merge similar buttons, consolidate forms, group related content.
- One primary action, few secondary, everything else tertiary or hidden.

**Visual**
- 1–2 colours plus neutrals. One font family, 3–4 sizes, 2–3 weights.
- Remove decoration that serves neither hierarchy nor function.
- Flatten nesting; never nest cards; use spacing and alignment instead of cards for basic layout.
- One spacing scale.

**Layout**
- Simple vertical flow over complex grids where possible.
- Move sidebar content inline or hide it.
- Pick one alignment and keep it. Generous whitespace.

**Interaction**
- Fewer choices, smart defaults, inline editing instead of modal flows.
- Remove steps. One obvious next action.

**Content**
- Cut filler, not meaning. Active voice ("Save changes"). Plain language.
- Short paragraphs and clear headings. No headers restating intros, no marketing fluff.

**Code**
- Remove dead CSS, unused components and orphaned files.
- Flatten component trees; consolidate styles; cut variants to the few that cover most cases.

**Avoid:** removing needed functionality or decision-making information, dropping labels or ARIA, minimalism that turns into mystery, erasing hierarchy, oversimplifying complex domains.

## Verify

- Tasks complete faster with less cognitive load.
- Every necessary feature is still reachable.
- What matters most is obvious.

If you removed features or options, note why, whether they need another access point, and what feedback to watch.
