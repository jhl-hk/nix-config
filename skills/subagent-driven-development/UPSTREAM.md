# Upstream

| | |
|---|---|
| Source | https://github.com/obra/superpowers — `skills/subagent-driven-development/` |
| Commit | `b36e0829c6d0140e93cfef2ca599b1b07d4a7797` (v6.3.0) |
| License | MIT |

## Local changes

- Harness-neutral: `superpowers:` prefixes removed; templates use `Dispatch a subagent:` with a required `model`; resuming an implementer means messaging the live agent.
- Both flowcharts converted from dot to mermaid; worktree and finishing handoffs marked `REQUIRED SUB-SKILL`.
- Workspace `.superpowers/sdd/` → `.temp/sdd/` (SKILL.md, scripts/sdd-workspace, scripts/task-brief, scripts/review-package); legacy flat-ledger note removed.
- Example workflow: `docs/plans/` paths; hook example no longer names `~/.config/superpowers/hooks/`.
