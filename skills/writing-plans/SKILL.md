---
name: writing-plans
description: Use when you have a spec or requirements for a multi-step task, before touching code. Not for an unshaped idea; use brainstorming.
---

# Writing Plans

Write implementation plans for an engineer who is skilled but knows nothing about this codebase, toolset or domain, and is weak at test design. Give every file to touch, the code, the tests, the docs to check and how to verify — as bite-sized tasks. DRY, YAGNI, TDD, frequent commits.

If the work runs in an isolated worktree, the using-git-worktrees skill creates it at execution time.

**Save plans to** `docs/plans/YYYY-MM-DD-<feature-name>.md` (a user-specified location wins).

## Scope check

A spec covering several independent subsystems should have been split during brainstorming. If it was not, suggest one plan per subsystem; each plan must produce working, testable software on its own.

## File structure

Before defining tasks, map which files are created or modified and what each is responsible for. This locks in the decomposition.

- One clear responsibility per file, with well-defined interfaces (why small, focused files: see brainstorming, "Design for isolation").
- Files that change together live together. Split by responsibility, not by technical layer.
- In existing codebases follow established patterns. Do not restructure large files unilaterally, but splitting a file you are modifying that has grown unwieldy is reasonable.

Each task should produce a self-contained change that makes sense on its own.

## Task sizing

A task is the smallest unit that carries its own test cycle and is worth a fresh reviewer's gate. Fold setup, configuration, scaffolding and docs into the task whose deliverable needs them; split only where a reviewer could reject one task while approving its neighbour. Every task ends with an independently testable deliverable.

Each **step** is one action (2–5 minutes): write the failing test; run it and see it fail; write the minimal code to pass; run the tests and see them pass; commit.

## Plan header

Every plan starts with:

```markdown
# [Feature Name] Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (default; executing-plans only when inline execution is requested) to implement this plan task by task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

**Spec:** [path to the spec/design doc this plan implements — the plan
argues from the spec, so the spec travels with it; executors read both]

## Global Constraints

[The spec's project-wide requirements — version floors, dependency limits,
naming and copy rules, platform requirements — one line each, with exact
values copied verbatim from the spec. Every task's requirements implicitly
include this section.]

---
```

## Task structure

````markdown
### Task N: [Component Name]

**Files:**
- Create: `src/exact/path/to/file.ts`
- Modify: `src/exact/path/to/existing.ts:123-145`
- Test: `src/exact/path/to/file.test.ts`

**Interfaces:**
- Consumes: [what this task uses from earlier tasks — exact signatures]
- Produces: [what later tasks rely on — exact function names, parameter
  and return types. A task's implementer sees only their own task; this
  block is how they learn the names and types neighboring tasks use.]

- [ ] **Step 1: Write the failing test**

```ts
import { expect, test } from "bun:test";
import { fn } from "./file";

test("specific behavior", () => {
  expect(fn(input)).toBe(expected);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bun test src/exact/path/to/file.test.ts -t "specific behavior"`
Expected: FAIL with "Export named 'fn' not found"

- [ ] **Step 3: Write minimal implementation**

```ts
export function fn(input: Input): Output {
  return expected;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bun test src/exact/path/to/file.test.ts -t "specific behavior"`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add src/exact/path/to/file.test.ts src/exact/path/to/file.ts
git commit -m "feat: add specific feature"
```
````

## No placeholders

Every step contains the actual content needed. These are plan failures:

- "TBD", "TODO", "implement later", "fill in details"
- "Add appropriate error handling" / "add validation" / "handle edge cases"
- "Write tests for the above" without the test code
- "Similar to Task N" — repeat the code; tasks may be read out of order
- Steps that say what to do without showing how (code steps need code blocks)
- Types, functions or methods not defined in any task

## Self-review

After writing the plan, check it against the spec yourself (not via a subagent):

1. **Spec coverage:** for each requirement, point to the task that implements it. Add a task for any gap.
2. **Placeholder scan:** search for the patterns above and fix them.
3. **Type consistency:** names and signatures in later tasks match earlier ones (`clearLayers()` in Task 3 vs `clearFullLayers()` in Task 7 is a bug).

Fix inline; no second review pass.

## Execution handoff

After saving, execute with subagent-driven-development by default: **REQUIRED SUB-SKILL:** Use subagent-driven-development (fresh subagent per task, a task review after each, a final whole-branch review).

Use executing-plans (inline, in this session) only if the user asks for inline execution or the harness has no subagents.
