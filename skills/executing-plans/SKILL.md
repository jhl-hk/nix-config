---
name: executing-plans
description: Use when you have a written implementation plan to execute in a separate session with review checkpoints
---

# Executing Plans

Load the plan, review it critically, execute every task, report when complete.

If subagents are available, use the subagent-driven-development skill instead of this one.

## Process

### 1. Load and review the plan

1. **REQUIRED SUB-SKILL:** Use using-git-worktrees to create or verify an isolated workspace. Never start implementation on main/master without explicit user consent.
2. Read the plan file.
3. Review it critically for questions or concerns. Raise any with the user before starting.
4. No concerns: put the plan's items on the todo list and proceed.

### 2. Execute tasks

For each task: mark it in progress, follow each step exactly (the plan has bite-sized steps), run the verifications it specifies, mark it complete. Load any skill the plan names.

### 3. Complete development

After all tasks are complete and verified: **REQUIRED SUB-SKILL:** Use finishing-a-development-branch — verify tests, present options, execute the choice.

## Stop and ask

Stop immediately when:

- you hit a blocker (missing dependency, failing test, unclear instruction);
- the plan has gaps that prevent starting;
- you don't understand an instruction;
- verification fails repeatedly.

Ask rather than guess; don't force through blockers.

Return to step 1 when the user updates the plan after your feedback, or when the approach needs rethinking.
