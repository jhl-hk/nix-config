# Upstream

| | |
|---|---|
| Source | https://github.com/obra/superpowers — `skills/test-driven-development/` |
| Commit | `b36e0829c6d0140e93cfef2ca599b1b07d4a7797` (v6.3.0) |
| License | MIT |

## Local changes

- Cycle flowchart converted from dot to mermaid.
- Red-flags list and rationalizations table merged into one table.
- `npm test` → `bun test` in examples; TypeScript examples kept.
- `writing-good-tests.md`: `superpowers:` prefix removed.
- Repetition of the delete/no-exceptions rule removed: the "skip TDD just this once" line, Debugging Integration (its rule now opens Example: Bug Fix) and Final Rule (Iron Law and the When to Use exceptions carry it). Multi-sentence rationalization rows shortened to one sentence each; every row kept.
- `writing-good-tests.md`: "Tests Ship With the Implementation" removed (restated the TDD cycle; its maintenance-cost point moved into Quick Reference); Warning Signs merged into Quick Reference as a third column.
