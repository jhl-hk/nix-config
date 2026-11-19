---
name: using-superpowers
description: Use at the start of a session or task to decide which skills to load, and whenever unsure whether a skill applies.
---

If you were dispatched as a subagent for a specific task, skip this skill.

## The rule

Before any response or action — including clarifying questions, exploring the codebase, or checking files — load every skill that might apply. If it turns out not to fit, drop it.

Before entering plan mode, load brainstorming if you have not already.

Then say "Using [skill] to [purpose]" and follow the skill exactly. If it has a checklist, put each item on the todo list.

## Priority

When several skills apply, process skills come first: they set the approach, then domain skills carry it out.

- "Let's build X" → brainstorming, then domain skills.
- "Fix this bug" → systematic-debugging, then domain skills.

## Red flags

These thoughts mean you are rationalizing:

| Thought | Reality |
|---|---|
| "This is just a simple question" | Questions are tasks. Check for skills. |
| "Let me explore / gather context first" | Skills tell you how to explore. Check first. |
| "I remember this skill" | Skills change. Read the current version. |
| "The skill is overkill" | Simple things become complex. Use it. |
| "I'll just do this one thing first" | Check before doing anything. |

## User instructions

Global instruction files (AGENTS.md, CLAUDE.md) and direct requests take precedence over skills, which override default behavior. Skip a skill's workflow only when the user explicitly says so.
