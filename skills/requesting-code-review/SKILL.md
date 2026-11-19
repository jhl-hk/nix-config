---
name: requesting-code-review
description: Use when completing tasks, implementing major features, or before merging, to get work reviewed against its requirements. Not for per-task review inside subagent-driven-development; that skill has its own task reviewer.
---

# Requesting Code Review

Dispatch a code reviewer subagent to catch issues before they cascade. The reviewer gets precisely crafted context — never your session's history. Reviewing the diff inline yourself burns the context you need to keep driving the work; with a subagent, the diff and the evaluation live in its context and only the findings come back.

**Core principle:** Review early, review often.

## When to request review

**Mandatory:**
- After completing a major feature
- Before merging to main
- The final whole-branch review in subagent-driven-development (which uses this skill's template)

**Optional but valuable:**
- When stuck (fresh perspective)
- Before refactoring (baseline check)
- After fixing a complex bug

## How to request

**1. Get git SHAs:**
```bash
BASE_SHA=$(git rev-parse HEAD~1)  # or origin/main
HEAD_SHA=$(git rev-parse HEAD)
```

**2. Dispatch a subagent** with the template at [code-reviewer.md](code-reviewer.md), on the most capable available model, filling the placeholders:
- `[DESCRIPTION]` — brief summary of what you built
- `[PLAN_OR_REQUIREMENTS]` — what it should do
- `[BASE_SHA]` — starting commit
- `[HEAD_SHA]` — ending commit

**3. Act on feedback:**
- Fix Critical issues immediately; never ignore them.
- Fix Important issues before proceeding.
- Note Minor issues for later.
- Don't argue with valid technical feedback. If the reviewer is wrong, push back with technical reasoning, show code or tests that prove it works, or request clarification.

Never skip review because "it's simple".

## Example

```
[Just completed Task 2: Add verification function]

You: Let me request code review before proceeding.

BASE_SHA=$(git log --oneline | grep "Task 1" | head -1 | awk '{print $1}')
HEAD_SHA=$(git rev-parse HEAD)

[Dispatch code reviewer subagent]
  DESCRIPTION: Added verifyIndex() and repairIndex() with 4 issue types
  PLAN_OR_REQUIREMENTS: Task 2 from docs/plans/deployment-plan.md
  BASE_SHA: a7981ec
  HEAD_SHA: 3df7661

[Subagent returns]:
  Strengths: Clean architecture, real tests
  Issues:
    Important: Missing progress indicators
    Minor: Magic number (100) for reporting interval
  Assessment: Ready to proceed

You: [Fix progress indicators]
[Continue to Task 3]
```
