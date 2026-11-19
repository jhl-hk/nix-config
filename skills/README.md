# Skills

Every directory here that contains a `SKILL.md` is deployed to `~/.agents/skills/<name>` (see `home/jhl/common/core/skills.nix`). omp reads it today; other agents may read it for testing.

This file is the writing standard for every skill in this directory.

## A. Language and reader

1. **English only** — description, body, references, code comments. Skills shared across JianyueLab (the `JianyueLab/skills` and `Docs` repos) follow their own repo's language instead.
2. **No harness-specific tool names.**

   | Instead of | Write |
   |---|---|
   | Skill tool, `superpowers:<name>` | `**REQUIRED SUB-SKILL:** Use <name>` (see C.8) |
   | TodoWrite | the todo list |
   | Task tool, Agent tool, `run_in_background` | dispatch a subagent |
   | AskUserQuestion | ask the user |
   | `Read(offset, limit)` | read a line range |
   | Edit / Write | edit / write the file |

3. **No hard-coded harness paths.** Refer to another skill by name.
4. **Any agent is the reader.** If a step works in only one harness (hooks, for example), say which.

## B. Frontmatter

1. `name`: lowercase letters, digits and hyphens only (no parentheses or special characters), matching the directory name. Verb-first or named after the core insight: `condition-based-waiting` over `async-test-helpers`; gerunds suit processes (`writing-plans`).
2. `description` answers only "should I load this now?": triggering situations, never the skill's own workflow. An agent that reads a workflow summary follows it and skips the body.

   ```yaml
   # no: summarizes the process
   description: Use for TDD - write test first, watch it fail, write minimal code, refactor
   # yes: triggers only
   description: Use when implementing a feature or fixing a bug, before writing implementation code.
   ```

3. Use words an agent will match: library names, file types, commands, exact error strings (`wrangler`, `bird.conf`, `ENOTEMPTY`).
4. When scope overlaps a neighbour, end with the boundary: `Not for X; use <skill>.`
5. Keep every other field as is (`disable-model-invocation`, `license`, ...).

No length limit on either. Concise and plain; every sentence carries information.

## C. Body

1. **Shape:**

   ```markdown
   # Skill Name
   ## Overview            core principle in 1-2 sentences
   ## When to Use         symptoms and use cases; when NOT to use; small flowchart if the decision is non-obvious
   ## Core Pattern        before/after comparison (techniques and patterns)
   ## Quick Reference     table or bullets for scanning
   ## Implementation      inline for simple patterns; link a file for heavy reference or tools
   ## Common Mistakes     what goes wrong + fixes
   ## Real-World Impact   optional; concrete results
   ```

   Reference skills may open straight on the table.
2. **Cut:** preamble ("This skill helps you..."), history ("used to be..."), motivation, and repetition — one rule stated once, not again in a red-flags list and a rationalization table. Keep one sentence of "why" when it changes behaviour.
3. **Keep:** every command, flag, path, version, threshold, error string, gotcha, decision table and informative code example. In doubt, keep it.
4. Tables for comparisons, numbered lists for steps, code blocks for code, prose only for concepts.
5. **Do not copy another skill.** Reference it by name instead of repeating its tables.
6. Material needed every time stays in `SKILL.md`; large reference goes in `references/`, with a line saying when to read which file. Existing file names and links stay valid.
7. Scripts may be edited when they do not fit this environment (paths, scratch locations, branding, harness assumptions). Record every script change in `UPSTREAM.md`. Binaries and generated data stay untouched.
8. **Cross-references** name the skill and mark whether it is required: `**REQUIRED SUB-SKILL:** Use <name>` (must be loaded and followed), `**REQUIRED BACKGROUND:** <name>` (must be understood first). A plain mention ("see <name>", "or use <name>") for optional or alternative skills. Never `@`-link a file: it force-loads the whole file into context.
9. **Flowcharts** are ```` ```mermaid ```` blocks, used only for a non-obvious decision point, a process loop where an agent might stop too early, or an "A vs B" choice. Never for reference material (table), linear steps (numbered list) or code (code block). Node labels carry meaning (no `step1`, `helper2`) and never contain code.

## D. Environment

Decide per project: check `package.json`, `go.mod`, `Cargo.toml`, `*.xcodeproj` first. Usual stack:

| Layer | Default |
|---|---|
| Frontend | Astro; interactive islands in Vue or React; Tailwind; `@jianyuelab/tokens` / `@jianyuelab/ui` |
| Backend | Go; Rust accepted |
| Native | Swift |
| Deploy | Talos Kubernetes, Dokploy, Cloudflare |
| Tooling | bun / bunx; nix-darwin + home-manager |

Examples use this stack first. Mark framework-specific passages: "Vue only", "React only". For JianyueLab conventions (components, Passport, deployment), point to the `jianyuelab-*` / `passport-*` skill.

## E. Third-party skills

1. Keep the upstream `LICENSE` and add `UPSTREAM.md`: source URL and path, commit, license, and a `Local changes` list.
2. Once edited, a skill has diverged: never re-sync it wholesale. Merge upstream changes by hand.

## F. Verification

1. Changes are proposed and agreed before they are written.
2. After writing, compare old and new line by line, list what was removed and why, and confirm no fact was lost.
3. Discipline skills (rules an agent may skip under pressure: TDD, debugging, verification) get pressure-tested with subagents: run the scenario without the skill and record the rationalizations, run it with the skill and confirm compliance, close the loopholes. Wording changes get micro-tests: 5+ runs per variant against a no-guidance control. Pure reference skills are exempt. **REQUIRED BACKGROUND:** writing-skills for the method.
4. Deployment changes: `nix eval`, then read the generated skill directories.

## G. Publishing

1. Commit and push the change.
2. For a third-party skill, consider sending a change that is useful beyond this setup upstream as a PR.
