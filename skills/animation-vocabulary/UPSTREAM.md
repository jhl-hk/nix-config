# Upstream

| | |
|---|---|
| Source | https://github.com/emilkowalski/skills — `skills/animation-vocabulary/` |
| Commit | `f7ce8c02d6e3c8f0d980a44c57bcc41a40254349` |
| License | MIT |

## Local changes

- Description rewritten as triggers plus boundary (animate).
- Removed the "Initial Response" greeting and the note about syncing with the upstream `/vocabulary` page.
- Quick Start, Instructions and Examples merged into Overview / Core Pattern. Glossary unchanged except "Layout thrashing" (below).
- Added a short When to Use.
- Three worked examples cut to one (Morph, which shows the alternates format); the other two only repeated glossary entries verbatim.
- Glossary "Layout thrashing" corrected: upstream defined it as animating width/height/top/left; it is interleaved layout reads and writes (forced synchronous reflow), matching animation-performance. The layout-property cost is kept as a contrast note in the same entry.
