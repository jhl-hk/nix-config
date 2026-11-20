# Upstream

| | |
|---|---|
| Source | https://github.com/obra/superpowers — `skills/systematic-debugging/` |
| Commit | `b36e0829c6d0140e93cfef2ca599b1b07d4a7797` (v6.3.0) |
| License | MIT |

## Local changes

- `superpowers:` prefixes removed; "Phase 4.5" reference fixed to Phase 4, step 5.
- Red-flags list and rationalizations table merged into one table.
- Removed authoring files: `CREATION-LOG.md`, `test-academic.md`, `test-pressure-1.md`, `test-pressure-2.md`, `test-pressure-3.md`.
- Flowcharts in `condition-based-waiting.md` and `root-cause-tracing.md` converted from dot to mermaid; TDD and verification references marked `REQUIRED SUB-SKILL`.
- Phase 4 requires using-git-worktrees before the first fix edit (fixes go on a new branch).
- `SKILL.md`: "Use this ESPECIALLY when" and "Don't skip when" lists removed (each item is a rationalization row); the table intro and the 3+-failures row point to Phase 4, steps 4–5 instead of restating them; Quick Reference moved up under When to Use.
- The empty-`projectDir` story is told once: the trace in `root-cause-tracing.md` (now ending in a "Fix at the Source" step), the layers in `defense-in-depth.md`. Removed from `root-cause-tracing.md`: the "Real Example" retelling, the Key Principle flowchart, Stack Trace Tips (folded into Adding Stack Traces), the dated Real-World Impact. Manager names unified (`Session.initializeWorkspace()` for layer 2, `WorktreeManager` for layer 3).
- `defense-in-depth.md`: Key Insight merged into Why Multiple Layers; data-flow retelling replaced by a pointer; layer 1 text says "is a directory" (matching the code, not "writable"); layer 3 compares against `tmpDir + sep`; layer 4 uses `console.error` instead of `logger.debug`.
- `condition-based-waiting.md`: `waitFor` calls pass the required `description` argument; `waitForEvent` call matches the example's signature; duplicate "document WHY" bullet and the session date removed.
- `condition-based-waiting-example.ts`: dated header replaced by a note that it imports Lace types and won't compile here; duplicate result line removed.
- `npm test` → `bun test` (`root-cause-tracing.md`, `find-polluter.sh`).
- `find-polluter.sh` (script): exits with code 2 if the pollution exists before the first test (previously it skipped every test and reported "all clean"); test command read from `TEST_CMD`, default `bun test`; test paths collected into an array and quoted (no word splitting on spaces); header says it runs tests one by one (was "Bisection"); unreachable in-loop pre-existence check removed.
