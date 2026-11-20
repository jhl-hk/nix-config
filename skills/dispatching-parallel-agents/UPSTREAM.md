# Upstream

| | |
|---|---|
| Source | https://github.com/obra/superpowers — `skills/dispatching-parallel-agents/` |
| Commit | `b36e0829c6d0140e93cfef2ca599b1b07d4a7797` (v6.3.0) |
| License | MIT |

## Local changes

- Description: boundary with subagent-driven-development added.
- Flowchart converted from dot to mermaid.
- `Subagent (general-purpose):` → `Dispatch a subagent:`; "multiple calls in one response" wording made harness-neutral.
- "When NOT to Use" merged into "Don't use when"; "Verification" merged into "Review and Integrate"; session narrative condensed into Real-World Impact.
- "Why subagents" paragraph replaced by a pointer to subagent-driven-development (single home).
- Overview motivation folded into the core principle.
- Scope / context / constraints / output stated once in step 2, each with its failure mode; "Agent Prompt Structure" list and the Common Mistakes ❌/✅ pairs folded into it; the example prompt moved under step 2.
- Flowchart: "Multiple failures?" gains its `no` branch (investigate yourself, systematic-debugging).
