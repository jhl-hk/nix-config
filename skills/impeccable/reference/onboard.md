> **Additional context needed**: the "aha moment" you want users to reach, and users' experience level.

Get users to first value fast. Onboarding gets people to the moment that proves the product is worth their time; it does not teach everything.

## Assess

1. **Challenge:** what users are trying to do, where they get stuck or drop off, the aha moment.
2. **Users:** experience level, motivation (exploring or required by work), time available, alternatives they know.
3. **Success:** the minimum they must learn, the key first action (first project, first invite), and how you will know it worked (completion rate, time to value).

## Principles

- **Show, don't tell:** real functionality, not a separate tutorial mode; one concept at a time.
- **Optional:** experienced users can skip; never block the product.
- **Time to value:** front-load the few concepts that deliver most value; leave advanced features to contextual discovery.
- **Context over ceremony:** teach a feature when it is needed, at the point of use. Empty states are onboarding moments; see [clarify.md](clarify.md).
- **Respect intelligence:** concise; assume standard patterns are known.

## Patterns

**Initial onboarding**
- Welcome: value proposition, what users will accomplish, an honest time estimate, a skip option.
- Account setup: minimal required fields, say why each is asked, smart defaults, social login where appropriate.
- Core concepts: 1–3, interactive, with progress ("step 1 of 3").
- First success: something real, from pre-populated examples or templates; modest celebration; clear next step.

**Feature discovery**
- Contextual tooltips: first time the feature is seen, pointing at the element, brief benefit, dismissable with "don't show again", optional "Learn more".
- Announcements: what is new and why it matters, try it now, dismissable.
- Progressive: badges on new or unused features; reveal options gradually.

**Guided tours** (complex interfaces, major changes, domain tools)
- Spotlight one element, 3–7 steps, free click-through, "Skip tour", replayable from help.
- Interactive and workflow-framed ("Create a project", not "This is the project button"), with sample data so actions work.

**Interactive tutorials** (hands-on practice, unfamiliar or high-stakes concepts)
- Sandbox with sample data, a clear objective, step guidance, validation, a graduation moment.

**In-product help**
- Contextual help links, `?` icons near complex features, a searchable help centre, keyboard hints (`⌘K` on the search box), short videos for complex workflows.

## Implementation

- Tour libraries: Shepherd.js, Intro.js; positioning: Floating UI.
- Overlays: focus trap, backdrop, Esc to close.
- Persist seen and dismissed states (e.g. `localStorage.setItem('feature-tooltip-seen-reports', 'true')`) so onboarding shows once and never returns for returning users.
- Track completion and drop-off.

**Avoid:** long forced onboarding, obvious explanations, repeated tooltips, blocking all UI during a tour, a tutorial disconnected from the product, front-loading everything, a hidden skip.

## Verify

- Users finish quickly, understand, and take the intended next step.
- High skip rate means too long or not valuable; low completion means simplify.
- Time to first value is short.
