# Upstream

| | |
|---|---|
| Source | https://github.com/obra/superpowers — `skills/requesting-code-review/` |
| Commit | `b36e0829c6d0140e93cfef2ca599b1b07d4a7797` (v6.3.0) |
| License | MIT |

## Local changes

- Description: boundary with subagent-driven-development added.
- "After each task in subagent-driven development" replaced: that skill uses its own task reviewer and this template only for the final review.
- `general-purpose` subagent → `Dispatch a subagent:`; template gains a required `model` line.
- Placeholders unified to `[NAME]`; example plan path `docs/plans/`; reviewer worktree `/tmp/review-*` → `.temp/review-*`.
- Rationalizations table and red-flags list folded into the body.
- "Never your session's history" clause replaced by a pointer to subagent-driven-development (single home).
- BASE default `git rev-parse HEAD~1` → the recorded base or `git merge-base origin/main HEAD` (HEAD~1 truncates multi-commit work); the example uses a recorded base instead of `git log | grep "Task 1"`.
- "Don't argue with valid technical feedback…" replaced by a pointer to receiving-code-review.
- `code-reviewer.md`: "Critical Rules" DO/DON'T list removed (it restated Calibration and the per-issue format); its unique points (read before judging, never "looks good" unchecked, no vague findings, clear verdict) moved into Calibration. Example output headings aligned with the template (`Important (Should Fix)`, `Minor (Nice to Have)`, `Ready to merge?`); SKILL.md example assessment likewise.
