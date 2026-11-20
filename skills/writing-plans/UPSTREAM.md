# Upstream

| | |
|---|---|
| Source | https://github.com/obra/superpowers — `skills/writing-plans/` |
| Commit | `b36e0829c6d0140e93cfef2ca599b1b07d4a7797` (v6.3.0) |
| License | MIT |

## Local changes

- `SKILL.md` condensed; `superpowers:` prefixes and the "announce at start" line removed.
- Plan location `docs/superpowers/plans/` → `docs/plans/`.
- `plan-document-reviewer-prompt.md` deleted: nothing referenced it and it contradicted the skill's self-review rule ("not via a subagent", "no second review pass").
- Task template example: Python/`pytest` → bun + TypeScript (`bun:test`, `bun test -t`).
- Description: boundary with brainstorming added. "Small, focused files" rationale replaced by a pointer to brainstorming (single home).
- Execution handoff wording aligned with the two skills: subagent-driven-development runs a task review per task plus a final review; executing-plans runs inline in this session (no "checkpoints").
- Execution handoffs marked `REQUIRED SUB-SKILL`.
- Execution handoff: subagent-driven-development is the default; executing-plans only on request or without subagents.
