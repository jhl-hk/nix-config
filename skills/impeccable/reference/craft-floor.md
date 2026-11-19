# Craft floor

Load this after the direction is settled, and build without announcing the checklist. A pinned brief or the committed visual world overrides anything here except a line marked as a ban; your own habit does not. When the design hook is active it enforces the mechanical checks below as you edit: act on its findings instead of re-auditing each rule.

This file is the single home for contrast thresholds, component states, browser-surface theming and body line length. Other references link here.

## Verify

Each check is on the built result, not an intention. Run them together in each batched look at the render; the checks share one render.

- **Contrast:** body and placeholder text ≥4.5:1, large text ≥3:1, and non-text UI (controls, icons, focus indicators, input borders) ≥3:1 against adjacent colours. On coloured surfaces tint secondary text from that hue or the foreground; never grey.
- **Depth:** shadows carry an offset and a soft blur. A zero-offset coloured halo is decoration.
- **Spacing:** tight groups, generous separation, more space above a heading than below it. Read the computed values.
- **Motion:** one authored moment, not scattered effects and not one identical entrance on every section. Exponential ease-out from an already-visible default; the easing token and durations live in [animate.md](animate.md). Reach past transform and opacity: blur, backdrop-filter, clip-path, mask and shadow belong to the palette when they stay smooth.
- **Type:** body measure 65–75ch (data, tables and compact UI may run denser), display max 6rem, tracking floor -0.04em, balanced headings, obvious scale and weight steps. Run the real copy at every breakpoint and fix what overflows.
- **States:** every interactive component has default, hover, focus, active, disabled, loading and error; views have empty. Plus real content, working controls, responsive composition, visible keyboard focus. Loading inside content is a skeleton, not a centred spinner.
- **Overlays:** dropdowns, menus and popovers escape their container. An absolutely positioned overlay inside an `overflow: hidden` or `overflow: auto` ancestor gets clipped; use `<dialog>`, the popover API, `position: fixed`, or a portal.
- **Browser surfaces:** text selection, the caret, custom scrollbars, focus rings, underline offset and the numerals in tabular data ship with browser defaults. Theme them from the palette.
- **Consistency:** one component vocabulary across screens: same button shape, same form controls, same icon style. If "save" looks different in two places, one is wrong.
- **Copy:** the product's own language. Controls name their action; errors name the problem and the recovery.
- **Coverage:** every brief requirement present and findable within seconds.

## Refuse

These are the category's defaults, not bans: the brief's own words can earn any of them. Reaching for one when the axis is free means you were not deciding; recognising that means rewriting the element, not softening it.

Page scaffolds:

- Same-size cards of icon plus heading plus text as the page structure. Cards are the lazy container; nested cards are always wrong.
- The hero-metric template: big number, small label, supporting stats, accent.
- A kicker or eyebrow above a heading. **Ban**: no brief earns it back. Delete the label and let the heading carry its own weight.
- Section numbers (01 / 02 / 03) unless the sequence itself carries information the reader needs.
- A modal for a task that needs neither interruption nor protected focus. Exhaust inline and progressive alternatives first.

Surface habits:

- Gradient text. Emphasis comes from weight or size.
- Glass and blur as decoration rather than as a specific effect.
- A coloured `border-left` or `border-right` above 1px on cards, list items, callouts or alerts.
- Hard offset shadows (`box-shadow: 4px 4px 0`) outside a world that is actually neobrutalist. A world that did not choose the zero-blur block shadow never earns it as a default.
- Sparklines, progress rings and soft-shadowed rounded rectangles standing in for content.
- Monospace as a costume for "technical" rather than for code, data or measurement.
- A system display face (Impact, Arial Black, the platform sans) as the display voice of an own-world page. Source and self-host a face whose character matches the approved lettering; the closest installed font is a failure, not a fallback.
- Unicode glyphs or emoji standing in for an icon system. Icons come from a real library or authored SVG, in one consistent stroke and weight.
- Geometric masks standing in for organic contours. A circle, polygon or radial-gradient cutout approximating a photographic subject's edge reads worse than omitting it. Derive an alpha matte from the actual image, or produce a cut-out asset.
- Light or dark picked by category. Pick it from the use scene: who, where, under what ambient light.

The floor holds the mechanics; it never picks the direction. With every check green, spend the page on the committed world, and when torn between refined and committed, commit.
