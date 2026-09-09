---
name: conserving-context
description: Use when a task will touch multiple files, run commands with large output, or write large content — before the first Read, Bash, or dispatch.
---

# Conserving Context

## Overview

Every byte you pull into context stays resident for the rest of the session and is re-sent on every later turn. A 30KB full-file read in a 20-turn session is not paid once — it is paid 20 times.

**Core principle: locate before you pull.**

Measured across 40 real sessions (5,801 tool results): unbounded file reads were roughly half of all data pulled in; 82% of sessions re-read a file already in context; the agent's own tool *inputs* were 42.5% of total volume — nearly 1:1 with the data it pulled. Prose replies were 5%. Shortening your writing is not where the money is.

## The Iron Law

```
NEVER PULL WHAT YOU HAVE NOT SIZED
```

Locating is not sizing. A `grep` is a pull: on a common pattern it returns as much as `cat` would. Knowing *where* something is does not tell you *how much* comes back.

## The Pull Sequence

Three steps, in order, every time you go after something in a file you have not already sized:

1. **How big?** — `wc -l <file>`
2. **How many hits?** — `grep -c <pattern> <file>`
3. **Only now, pull — bounded by what step 2 told you** — `grep -m 5`, `sed -n '40,80p'`, or `Read(offset, limit)`

If step 2 answers the question (a count, a file list), you are done — stop there and do not pull. If step 2 returns a three-digit number, step 3 is bounded or it is a `cat` wearing a costume.

## Rules

### 1. Bound every pull — not just reads

The tool does not matter — the bound does. `sed -n '40,80p' f` and `Read(offset, limit)` are fine; `cat f` and an unbounded `Read` on a file you have not sized are not. Unknown file? `wc -l` first, then read the range.

Every search command carries a bound the same way: `-c`, `-l`, `-m N`, or `| head -N`. A bare `grep -n` on a large file is an unbounded pull.

### 2. Never re-read what is already in context

Read it this session and have not changed it? It is still there — scroll, don't re-fetch. After a successful `Edit`, the file's new state is known: re-reading "to verify" buys nothing, because `Edit` fails loudly when it does not apply.

### 3. Your inputs cost exactly what their outputs cost

Writing a file? One `Write` call, not a multi-part Bash heredoc that re-sends the growing document each part. Dispatching an agent? Hand it **paths and line ranges**, never pasted file bodies — it can read what it needs, and your paste stays resident in *your* context forever.

### 4. Count before you look

If the question is "how many" or "which files", `grep -c` / `grep -l` **is the answer** — never count lines by eye from a full match dump. If you do need to see matches, size the hit set with `-c` first; a three-digit count means bound the real search with `-m` or `| head`. Use `| wc -l`, `--stat`, `--oneline` on anything else that could be long. Pipe noisy commands (`git log`, test runners, builds) through a filter rather than eyeballing full output. A failing build's error lines are what you need, not its 800 successful lines.

### 5. Delegate what would flood you

Broad greps, multi-file audits, log trawls: dispatch and ask for the conclusion. See `superpowers:dispatching-parallel-agents` for when work splits, and `superpowers:subagent-driven-development` for handing artifacts over as files.

## When to Spend — the quality guardrail

Frugality that causes a wrong guess is a net loss: a re-run, a bad edit, and a re-read cost more than the read you skipped. **Spend without hesitation when:**

- **You are about to edit.** Read the actual target region first. Never edit from memory, from a filename, or from a grep line alone.
- **You are debugging.** One full read of the relevant file beats three speculative greps. Confusion is a signal to look at more, not less.
- **The answer determines the approach.** Cheap now, wrong branch later, is not cheap.
- **A bound would truncate the thing you need.** Read the whole config, the whole schema, the whole failing test.

Frugality means not pulling what you did not need. It never means guessing.

## Red Flags — STOP

- "Let me just `cat` it to see what's in there"
- "I'll read the whole file to be safe"
- "Let me re-read it to confirm my edit applied"
- "I'll paste the file into the subagent prompt so it has full context"
- "I'll dump the full test output and scan it"
- "I'm grepping instead of reading, so I'm already being careful"
- Writing a `grep` for a pattern you have not counted first
- "I'll write this file in three heredoc parts"

**All of these mean: locate first, bound the pull, or hand over a path.**

## Rationalizations

| Excuse | Reality |
|--------|---------|
| "It's only a 40KB file" | 40KB × every remaining turn. Cost scales with turns left, not with the one call. |
| "I need full context to be safe" | You need the *right* context. Grep tells you where it is. |
| "Re-reading verifies my edit" | `Edit` errors when it fails. A clean result is the verification. |
| "Pasting into the prompt is faster than the agent reading it" | Faster for the agent, permanent for you. Paths are free. |
| "I'll filter the output mentally" | You pay for it whether or not you read it. Filter in the shell. |
| "grep is my locating tool, it's fine" | An unbounded grep on a common pattern costs what `cat` costs. Bound the search too. |
| "Bounding might miss something" | Then it is a *spend* case — read it fully and deliberately, not by default. |

## Quick Reference

| Want | Do | Not |
|---|---|---|
| Find where X is defined | `grep -n X` → read that range | Read whole file |
| Count occurrences of X | `grep -c X` | `grep -n X` then count by eye |
| Search a common pattern | `grep -c` first, then `-m 5` / `\| head` | Bare `grep -n` |
| Check a file's shape | `wc -l` + `head -30` | `cat` |
| Verify an edit landed | Trust `Edit`'s success | Re-Read the file |
| Give an agent a file | Pass the path | Paste the body |
| See why a build failed | Pipe through `grep -i error` / `tail -40` | Full output |
| Write a long document | One `Write` | Multi-part heredoc |
| Audit many files | Dispatch, ask for conclusions | Read them in the main thread |
