# Upstream

| | |
|---|---|
| Source | https://github.com/obra/superpowers — `skills/brainstorming/` |
| Commit | `b36e0829c6d0140e93cfef2ca599b1b07d4a7797` (v6.3.0) |
| License | MIT |

## Local changes

- `SKILL.md` condensed and made harness-neutral; references to frontend-design, mcp-builder and elements-of-style removed; writing-plans handoff marked `REQUIRED SUB-SKILL`.
- Spec location `docs/superpowers/specs/` → `docs/specs/`.
- `spec-document-reviewer-prompt.md` deleted: nothing referenced it and it contradicted the skill's self-review-only rule.
- `SKILL.md`: approval rule stated once in the hard gate; red-flag rows that restated the gate or the heavier-path ratchet folded into those rules, the rest kept as Common Mistakes; process flowchart removed (it redrew the checklist); Overview heading added; the companion is started only after reading `visual-companion.md`; that file's browser-vs-terminal lists merged into "Decide per question".
- `visual-companion.md`: per-harness launch sections merged into one; session paths updated; "When to Use" points to SKILL.md; File Naming section and the duplicate "iterate" tip removed (both in The Loop); undefined `$SESSION_DIR` → parent of `state_dir`; "last `choice` event" → "last click's `choice`" (helper.js sends `type:"click"`); "file-creation tool" → "write the file directly".
- Scripts: session files in `<project>/.temp/brainstorm/` instead of `.superpowers/brainstorm/` or `/tmp`; `--project-dir` defaults to `$PWD`; `stop-server.sh` no longer deletes the session dir.
- `server.cjs`: removed the superpowers logo (remote image), version string and GitHub link from rendered pages; orphaned `.brand*` CSS rules removed from the waiting page.
- `frame-template.html`: `<title>Superpowers Brainstorming</title>` → `Brainstorm Companion`; orphaned `.brand*` CSS rules and the "header branding" comment removed.
- `start-server.sh`: Usage line lists `--idle-timeout-minutes` and `--open`.
