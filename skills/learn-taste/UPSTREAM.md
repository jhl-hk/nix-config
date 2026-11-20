# Upstream

| | |
|---|---|
| Source | https://github.com/emilkowalski/skills — `skills/learn-taste/` |
| Commit | `f7ce8c02d6e3c8f0d980a44c57bcc41a40254349` |
| License | MIT |

## Local changes

- Description rewritten to triggers; disable-model-invocation kept.
- Rules now go to the project's AGENTS.md (Design rules section); DESIGN.md only as overflow with a pointer from AGENTS.md. DESIGN.md is written in impeccable `document`'s format (canonical sections only, Named Rules or Do/Don't bullets; created with `document` when missing; sidecar refreshed when present).
- Transcript lookup made harness-neutral (no Claude Code path).
- Invocation table no longer uses slash commands.
- Added When to Use with Not-for boundaries (one-off fixes; DESIGN.md generation → impeccable `document`).
- Phase 2 ASCII decision tree → mermaid flowchart; Phase 4 ASCII tree → table.
- "Propose, then stop" stated once (Hard Rule 3), "never change component code" once (Phase 6), "never add a rule the user didn't express" once (Hard Rule 1); Phase 5 and prune point to Hard Rule 3.
