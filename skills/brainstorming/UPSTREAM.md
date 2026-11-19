# Upstream

| | |
|---|---|
| Source | https://github.com/obra/superpowers — `skills/brainstorming/` |
| Commit | `b36e0829c6d0140e93cfef2ca599b1b07d4a7797` (v6.3.0) |
| License | MIT |

## Local changes

- `SKILL.md` condensed and made harness-neutral; process flowchart converted from dot to mermaid; references to frontend-design, mcp-builder and elements-of-style removed; writing-plans handoff marked `REQUIRED SUB-SKILL`.
- Spec location `docs/superpowers/specs/` → `docs/specs/` (SKILL.md, spec-document-reviewer-prompt.md).
- `spec-document-reviewer-prompt.md`: `Subagent (general-purpose):` → `Dispatch a subagent:`.
- `visual-companion.md`: per-harness launch sections merged into one; session paths updated.
- Scripts: session files in `<project>/.temp/brainstorm/` instead of `.superpowers/brainstorm/` or `/tmp`; `--project-dir` defaults to `$PWD`; `stop-server.sh` no longer deletes the session dir.
- `server.cjs`: removed the superpowers logo (remote image), version string and GitHub link from rendered pages.
