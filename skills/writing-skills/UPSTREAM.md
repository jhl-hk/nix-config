# Upstream

| | |
|---|---|
| Source | https://github.com/obra/superpowers — `skills/writing-skills/` |
| Commit | `b36e0829c6d0140e93cfef2ca599b1b07d4a7797` (v6.3.0) |
| License | MIT |

## Local changes

- `SKILL.md` rewritten: the writing standard now lives in `skills/README.md` (name, description, body shape, cross-references, mermaid flowcharts, verification, publishing); this skill keeps when-to-create, skill types, the TDD mapping, RED-GREEN-REFACTOR, form-vs-failure, bulletproofing, micro-tests, discoverability and the checklist. Length limits, word budgets, dot flowchart guidance and the separate red-flags list removed; Iron Law scoped to README F.3.
- Deleted `anthropic-best-practices.md` (platform-doc copy contradicting the README, 14 dangling links), `examples/CLAUDE_MD_TESTING.md`, `render-graphs.js`, `graphviz-conventions.dot`.
- `testing-skills-with-subagents.md`: `superpowers:` prefix and the CLAUDE_MD_TESTING link removed; `/tmp` example path replaced; red-flags list and rationalization table merged into one table.
- `persuasion-principles.md` unchanged (its "announce skill usage" example matches the global instruction file).
