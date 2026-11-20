# Typography, design principles and process

Read when setting Apple-style type (tracking, leading, optical sizing), reviewing a design against Apple's principles, or planning how to prototype and test an interaction. General visual direction and design systems: impeccable or design-taste-frontend.

## Typography

- Tracking is size-specific: negative on large display text (`-0.02em`), slightly positive on small text, body near `0`.
- Leading scales inversely with size: tight headings, looser body; looser for tall-ascender scripts, tighter for dense UI.
- Hierarchy from weight + size + leading together; emphasize with weight.
- Respect user text size: spacing in `rem`/`em`.
- Default to the system font (optical sizing and tracking tables built in).

```css
:root { font: 100%/1.5 system-ui, sans-serif; }
.display {
  font-size: clamp(2rem, 5vw, 4rem);
  line-height: 1.05;
  letter-spacing: -0.02em;
  font-optical-sizing: auto;
}
```

## Design principles

Apple's eight (*Principles of Great Design*):

1. **Purpose** — decide what not to build; every feature spends the user's time, attention and trust.
2. **Agency** — offer choices; easy undo for slips; confirmation dialogs only for destructive, irreversible actions (overuse trains click-through).
3. **Responsibility** — ask for permissions at the right moment, only what's needed; anticipate misuse, especially with AI (an allergy-aware recipe app must not suggest a harmful ingredient); add previews, confirmations, disclaimers; cut features whose risk outweighs value.
4. **Familiarity** — metaphors neither too literal nor too abstract (trash can = delete), honoring their physics; same look = same behavior and place (close is top-left on macOS); break a pattern only when proven better by testing.
5. **Flexibility** — adapt to platform (iPhone quick touch; desktop deep workflows, precise pointer) and to age, language, expertise, accessibility; allow personalization when no layout fits all.
6. **Simplicity, not minimalism** — plain language, fewer steps, hierarchy via order, spacing, contrast; adding context can simplify (scrubber showing time remaining); common path first, advanced one level deeper.
7. **Craft** — every spacing, timing and alignment value is defensible; jittery scroll, misaligned icons, layouts breaking on rotation read as carelessness; keep iterating.
8. **Delight** — the result of the other seven; choose the target emotion (calm, confident, excited) and reinforce it.

Tactical rules:

- Feedback has four kinds: status, completion, warning, error. Validate inline, not on submit.
- Wayfinding: every screen answers where am I, where can I go, what's there, how do I get out.
- Proximity implies relationship; place controls near and mirroring what they change. Needing a label signals weak mapping.
- Specific labels ("Progress", "Library") beat generic ones ("Home").

## Process

- Prototype interactively; a working demo sets the bar for the final build.
- Design interaction and visuals together.
- Test with real people in context; review motion in slow motion / frame by frame.
