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
