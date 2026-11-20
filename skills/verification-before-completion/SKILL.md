---
name: verification-before-completion
description: Use when about to claim work is complete, fixed, or passing, or before committing or creating PRs
---

# Verification Before Completion

## Overview

**Core principle:** Evidence before claims, always.

**Violating the letter of this rule is violating the spirit of this rule.**

## The Iron Law

```
NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE
```

If you haven't run the verification command in this message, you cannot claim it passes.

Applies before any claim of success or completion, any expression of satisfaction or positive statement about work state, committing, opening a PR, completing a task, moving to the next task, and delegating to agents — in any wording: exact phrases, paraphrases, synonyms or implications.

## The Gate Function

```
BEFORE claiming any status or expressing satisfaction:

1. IDENTIFY: What command proves this claim?
2. RUN: Execute the FULL command (fresh, complete)
3. READ: Full output, check exit code, count failures
4. VERIFY: Does output confirm the claim?
   - If NO: State actual status with evidence
   - If YES: State claim WITH evidence
5. ONLY THEN: Make the claim

Skip any step = lying, not verifying
```

## Common Failures

| Claim | Requires | Not Sufficient |
|-------|----------|----------------|
| Tests pass | Test command output: 0 failures (e.g. "34/34 pass") | Previous run, "should pass", "looks correct" |
| Linter clean | Linter output: 0 errors | Partial check, extrapolation |
| Build succeeds | Build command: exit 0 | Linter passing, logs look good |
| Bug fixed | Test original symptom: passes | Code changed, assumed fixed |
| Regression test works | Red-green cycle: write → run (pass) → revert fix → run (MUST FAIL) → restore → run (pass) | Test passes once |
| Agent completed | VCS diff shows changes; verify them, report the actual state | Agent reports "success" |
| Requirements met | Re-read the plan, verify each item on a line-by-line checklist, report gaps or completion | Tests passing |

## Red flags and rationalizations

Any of these means: stop and run the verification.

| Thought or wording | Reality |
|---|---|
| "Should work now" / "probably" / "seems to" | Run the verification. |
| "Great!" / "Perfect!" / "Done!" before verifying | Satisfaction is a success claim. Verify first. |
| "I'm confident" | Confidence ≠ evidence. |
| About to commit, push or open a PR | Verification comes before, not after. |
| "Agent said success" | Verify independently: check the VCS diff. |
| "Partial check is enough" / "Linter passed" | Partial proves nothing; a linter is not a compiler. |
| "Just this once" / "I'm tired" | No exceptions; exhaustion is not an excuse. |
| "Different words so the rule doesn't apply" | Any wording that implies success without a verification run counts. |
