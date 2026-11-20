# Upstream

| | |
|---|---|
| Source | https://github.com/emilkowalski/skills — `skills/choreograph/` |
| Commit | `f7ce8c02d6e3c8f0d980a44c57bcc41a40254349` |
| License | MIT |

## Local changes

- Description rewritten as triggers plus boundaries (animate, gsap-web, improve-animations, page-transition-animation).
- Removed the "Initial Response" greeting and the repository-content-is-data rule.
- Replaced references to deleted find-animation-opportunities / remove-animations with improve-animations.
- Body restructured to Overview / When to Use / Core Pattern / Quick Reference / Implementation / Common Mistakes; relationship decision tree converted to mermaid; budgets and tools as tables; posture and tone prose condensed. All values, rules and recipes kept.
- When to Use: dropped the two lines repeating the description's boundaries.
- Budgets: stagger step and the 300ms product budget now cite animate; the marketing/hero stagger of 100–150ms became animate's 30–80ms (hero entrances keep 0.5–0.6s).
- Common Mistakes table removed: every row (parent + child stagger, `mode="wait"` vs `popLayout`, `custom` direction, reverse-staggered exits, clamped resize duration, awaited reset) is already a rule in Quick Reference or Implementation.
- RECIPES.md: preamble trimmed; CSS stagger `--step: 120ms` → `60ms` and `0.6s ease` → `0.6s var(--ease-out)`; resizing-container height curve `[0.25, 1, 0.5, 1]` → `[0.23, 1, 0.32, 1]` (`--ease-out`), content fade `[0.26, 0.08, 0.25, 1]` → quad ease-out `[0.25, 0.46, 0.45, 0.94]` (keeps "lighter curve, same family" true).
- Curve tokens in code carry a literal fallback (copy-paste safe without animate's :root tokens).
