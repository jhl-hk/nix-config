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
- Example workflow: `docs/plans/` paths; hook example no longer names `~/.config/superpowers/hooks/` (both since cut with the transcript, below).
- Decision chart: executing-plans only when inline execution is requested or no subagents; setup requires a new branch.
- Description: "default way to run a plan" plus boundaries with executing-plans and dispatching-parallel-agents.
- Stop rules stated once ("Continuous execution, rulings not stalls" + "Four things stop you"); the Final Review restatement removed. Core principle merged into the opening line.
- Pre-flight scan: the duplicate "rule on each conflict… record the ruling" sentence removed.
- Model Selection merged into one table; contradiction resolved by the turn-count rule: prose-spec implementers (even 1-2 files) take the mid-tier floor, complete-code transcription and single-file mechanical fixes the cheapest tier.
- Never-`HEAD~1` stated once (step 3); DONE handler points to it. "one Read call" → "one read". Resuming an implementer by message marked as needing a harness that can message a dispatched agent.
- `task-brief` output described as a per-task file that a re-run overwrites (was "uniquely named").
- Real-session anecdotes (compaction re-dispatch, 42k-char dispatch, worker-spawned reviewers, final fix wave) shortened to one clause each.
- Rationalization rows that restated body rules removed (fix-it-myself, drop-obvious-finding, ledger overhead, worker-spawned reviewer; the last folded into the no-subagents bullet). Mid-task questions handled through NEEDS_CONTEXT (flowchart node and the separate "asks questions" paragraph merged into it).
- Example workflow cut from the full ~65-line transcript to Task 2's fix round; its test command `test/recovery.test.js` → `bun test src/recovery.test.ts`.
- `implementer-prompt.md`: "ask now / ask while you work / always OK to pause" merged into one Questions section (questions go out as NEEDS_CONTEXT); TDD mandatory via test-driven-development (step, self-review question and TDD Evidence no longer conditional); `[directory]` → `[WORK_DIR]`, scene-setting → `[CONTEXT]`; Placeholders and returns block added.
- `task-reviewer-prompt.md`: "do not Read" → "do not read".
- `scripts/sdd-workspace`: header comment condensed.
