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
- `SKILL.md`: RED/GREEN/REFACTOR prose under the diagram cut (diagram, mapping table and checklist carry it; "triggering pressures", "nothing for hypothetical cases", description update and meta-test folded into the checklist); the "No exceptions" block and the example rationalization rows copied from test-driven-development replaced by pointers to it.
- `testing-skills-with-subagents.md` cut to scenario design, capturing rationalizations, meta-testing, bulletproof signs and the TDD bulletproofing example. Removed as repeats of `SKILL.md`: overview, TDD mapping and Quick Reference tables, RED/GREEN phase walkthroughs, the explicit-negation block and table rule (now a pointer to Bulletproofing), the testing checklist, "Common Mistakes (Same as TDD)" (its unique points, single pressure vs several and generic vs specific counters, moved into Pressure Types and `SKILL.md` Bulletproofing), The Bottom Line. The near-duplicate RED example scenario merged into the "Great scenario"; the "single pressure" scenario relabelled (it lists three); dated Real-World Impact folded into the example; persuasion-principles.md linked.
- `persuasion-principles.md`: the repeated N=28,000 / 33% → 72% bullets under the Meincke citation and the Quick Reference (restated the combinations table) removed; its "don't use all seven" point kept under the table. The "announce skill usage" example kept (matches the global instruction file).
