# hooks

Manage the **design detector hook** for the current project.

The hook runs the impeccable design detector on direct file edits to design-relevant files (`.tsx`, `.jsx`, `.html`, `.vue`, `.svelte`, `.astro`, `.css`, `.scss`, `.sass`, `.less`, `.ts`, `.js`). Where a post-edit hook exists it pushes a short reminder into the agent's context after the edit: findings get a correction prompt, pending issues get a re-nudge, and clean UI-ish files get a short ack unless quiet mode is on (`hook.quiet` in config). Plain `.ts` and `.js` files are scanned but stay quiet unless the detector finds something.

The detector rules run in two tiers. The per-edit hook surfaces only the immediate tier: mechanical, unambiguous problems worth interrupting an edit for, such as broken images, overflowing content, contrast and legibility failures, gradient text, glow shadows, and design-system drift. Everything else (copy cadence, palette and typography taste, layout rhythm) is deferred to a deep pass on the `Stop` hook event, which runs the full rule set over every UI file touched in the session and surfaces the remaining findings once, deduplicated against what the per-edit pass already reported. A session with nothing left to report stops silently. Set `hook.perEditRules` to `"all"` in `.impeccable/config.json` to run the full rule set on every edit. Harnesses without a Stop deep pass keep the full detector per edit.

| Harness | Install target | Per-edit | Stop deep pass | Notes |
|---|---|---|---|---|
| Claude Code | `.claude/settings.local.json` (project); `~/.claude/settings.json` (user); a project hook in shared `.claude/settings.json` is honored in place | post-tool-use reminder | yes | |
| Codex | `.codex/hooks.json` | post-tool-use reminder | yes | Approve via `/hooks` on first use. |
| Cursor | `.cursor/hooks.json` | `postToolUse` on every agent file edit; reminder as `additional_context` after the tool result | no (its `stop` hook can only send a follow-up user message) | Enable under Settings -> Hooks. A manifest with a `preToolUse` gate (`hook-before-edit`) still works and can block a write; `hooks on`, re-vendoring, or `impeccable doctor --fix` moves it to `postToolUse`. |
| Grok Build | `.grok/hooks/impeccable.json` | PostToolUse scan marks touched files; no per-edit reminder (Grok discards that stdout) | yes, findings via Stop `additionalContext` | Requires `/hooks-trust` or `--trust`. Scan only the `end_turn` Stop; skip the observe-only Stop with `reason: "shutdown"`. |
| GitHub Copilot | `.github/hooks/impeccable.json`, committed and team-shared | post-tool-use reminder | no (stop-style events do not feed context back) | CLI loads it once committed to the default branch; the cloud agent reads it from the repo. |
| Gemini | `.gemini/settings.json`, merged into existing settings | none | none | Session and completion hooks only. Comments tolerated; a commented file is backed up to `settings.json.bak` before rewrite; invalid JSON is left alone. `BeforeTool` only rewrites shell commands running `build-phase`, on macOS and Linux; on Windows no session id reaches the shell, so the completion reminder stays silent. |
| Other harnesses (e.g. omp) | not supported | none | none | `impeccable context` emits `MANUAL_DETECTOR_REQUIRED`; act on it. |

Every hook is a mechanical pass. The reflexes no scanner catches live in [craft-floor.md](craft-floor.md), which the skill loads before it edits UI, so they apply whether or not a hook is wired. A session with no automatic hook gets one `MANUAL_DETECTOR_REQUIRED` directive from `impeccable context` asking for a single detector run at the end.

This command toggles the hook **per project** by editing `.impeccable/config.json` (the unified Impeccable config; hook runtime settings live under its `hook` key, and shared detector ignores live under `detector`). Per-developer overrides, including the install consent decision (`hook.consent`) the CLI records, live in the gitignored `.impeccable/config.local.json`. Set `hook.enabled: false` to turn the hook off, `hook.quiet: true` to silence the clean/pending acks, or `hook.auditLog` to a file path for an NDJSON log. The env vars `IMPECCABLE_HOOK_DISABLED`, `IMPECCABLE_HOOK_QUIET`, and `IMPECCABLE_HOOK_LOG` are honored and override these config values when set.

Declare server-side template extensions under **`detector.extensions`** when the project uses Blade, Twig, ERB, or Handlebars files; the hook skips them otherwise because they sit outside the built-in extension list. One entry per extension, `{ "ext": ".blade.php", "engine": "html" }`. `engine` picks the analyzer (`html` for markup templates, `text` for JS/TS/CSS-like files) and defaults to `html`. Match against the end of the filename, so double extensions like `.blade.php` and `.html.erb` work. Config only adds extensions; the built-in list always applies.

Manual `"<skill-base-dir>/scripts/impeccable" detect` scans use the same project filter config by default: `detector.ignoreRules`, `detector.ignoreFiles`, `detector.ignoreValues`, and `detector.designSystem.enabled`. `hook.enabled` only controls automatic hook execution, not manual CLI scans. Use `"<skill-base-dir>/scripts/impeccable" detect --no-config ...` for a raw detector run that ignores project config/context. Use `"<skill-base-dir>/scripts/impeccable" ignores ...` for direct CLI CRUD on the same detector ignores.

## Routing

The first argument is the action. Defaults to `status`.

| Action | What it does |
|---|---|
| `status` | Print current state, shared/local config paths, ignored rules / files / values, env override. |
| `on` | Set `enabled: true` in `.impeccable/config.json`, record local hook consent as accepted, and install/repair provider hook manifests when the skill is installed. |
| `off` | Set `enabled: false` in `.impeccable/config.json`. |
| `ignore-rule <id>` | Append `<id>` to `detector.ignoreRules`; for `overused-font`, requires `--all-values`. Suppresses the rule across the whole project. |
| `ignore-file <glob>` | Append `<glob>` to `detector.ignoreFiles`. Suppresses **every** rule for matching files. |
| `ignore-value <id> <value> [--shared] [--reason "..."]` | Append a rule/value suppression to shared `.impeccable/config.json`. |
| `ignore-value <id> <value> --local [--reason "..."]` | Append a private rule/value suppression to `.impeccable/config.local.json`. |
| `ignore-value <id> "*" --file <glob> [--file <glob>...]` | Turn one rule off in matching files only, leaving it active everywhere else. Repeat `--file`, or use `--file=<glob>` / `--files=<glob>`. A bare `"*"` with no `--file` is refused: use `ignore-rule <id>` if you really mean project-wide. |
| `reset` | Delete the project config, dedup cache, and Cursor pending queue, and remove the hook's entries from every provider manifest `on` installs, the committed Copilot file included (a team-shared `settings.json` that `on` never writes is never touched). |

## Flow

1. Resolve the action from the user's argument. If no action was given, default to `status`.
2. Invoke the admin script and pass the user's output through verbatim:

   ```bash
   "<skill-base-dir>/scripts/impeccable" hooks <action> [args...]
   ```

3. If `<action>` is `off`, follow up with a one-line note: "Done. New edits will not trigger the design hook in this project until you run `hooks on`."
4. If `<action>` is `on`, follow up with: "Done. The design hook will fire after the next file edit on a UI file."
5. If `<action>` is `ignore-value`, `ignore-file`, or `ignore-rule`, just print the script output. The default scope is shared `.impeccable/config.json`; add `--local` only when the user explicitly asks for a private exception.
6. If `<action>` is `status`, just print the script output. Do not add commentary unless the user asked a follow-up question.

## Triage findings

The hook itself never writes ignore config; every exception goes through `impeccable hooks`. Triage each finding into one of three outcomes:

- **Real design problem**: fix it. Never add an ignore to skip a fix or to push a blocked write through.
- **Confident false positive or sanctioned exception**: persist the narrowest ignore yourself and disclose it in your reply. The bar is evidence you can name: an intentional demo or fixture, documentation of bad design, literal or domain-appropriate motion (a ball that bounces), or a choice the user already confirmed. Put that evidence in `--reason` as `"<who decided: evidence>"`; write "user confirmed" only when the user actually did.
- **Unsure**: leave the finding standing and ask the user in one line. Ask once; a one-line question costs less than the hook re-firing on every later edit.

Self-serve stops at `ignore-value`. `ignore-file` and `ignore-rule` silence too much to add on your own judgment; ask the user first.

Prefer the narrowest exception:

- If the finding line shows an `ignore-value <rule> <value>` pair, pass it to `impeccable hooks ignore-value` with your `--reason`. This writes shared `.impeccable/config.json` by default.
- For value-specific findings such as `overused-font` and `bounce-easing`, use `ignore-value` for the specific value. Do not use `ignore-rule overused-font` for a specific font.
- If the finding has no value-specific command, such as `side-tab`, scope that one rule to the file: `ignore-value <id> "*" --file <path>`. Run `"<skill-base-dir>/scripts/impeccable" detect <path>` first to see what actually fires there.
- Reach for `ignore-file <path>` only when the whole file is out of scope for design review: a fixture, a generated artifact, a deliberate slop demo. It silences every rule for that file permanently, including rules that have not been written yet. A real UI surface with one noisy rule wants the file-scoped value ignore above.
- Use `ignore-rule <id>` only when the user asks to suppress that whole rule across the project. For broad overused-font suppression, use `ignore-rule overused-font --all-values` only when the user asks to ignore overused fonts generally.
- Prefer config ignores (the commands above) by default; they keep suppressions in one reviewable place. Reach for an inline comment only when the waiver must travel with a single file that leaves the repo (a generated/exported standalone document, an emailed HTML file). The supported marker is `impeccable-disable <rule>` (whole file) or `impeccable-disable-line` / `impeccable-disable-next-line` (one line), in any comment syntax, with an optional reason after `:` or `--`. The detector honors it by default; `--no-inline-ignores` or `--no-config` bypasses it.

Example value-specific exception:

```bash
"<skill-base-dir>/scripts/impeccable" hooks ignore-value overused-font Inter --shared --reason "User confirmed Inter is intentional"
```

Example self-served exception, with the evidence named:

```bash
"<skill-base-dir>/scripts/impeccable" hooks ignore-value bounce-easing bounce-ball --shared --reason "Agent: literal ball-bounce animation, bounce easing is the subject"
```

Example whole-rule font exception:

```bash
"<skill-base-dir>/scripts/impeccable" hooks ignore-rule overused-font --all-values --reason "User asked to ignore overused fonts generally"
```

Example one-rule-in-one-file exception, for a file that is still worth reviewing
for everything else:

```bash
"<skill-base-dir>/scripts/impeccable" hooks ignore-value design-system-font-size "*" --file "src/overlay/widget.js" --reason "Injected widget builds its own type scale; DESIGN.md's ramp describes the site"
```

Example whole-file exception, for a file that is out of scope entirely:

```bash
"<skill-base-dir>/scripts/impeccable" hooks ignore-file "src/legacy/Card.tsx"
```

## Constraints

- Never modify `.impeccable/config.json` or `.impeccable/config.local.json` by hand from this command. Always go through `impeccable hooks` so writes stay validated and the file shape stays consistent. One exception: `detector.extensions` has no admin action, so when the user asks to cover a template stack, edit that one field in `.impeccable/config.json` directly and leave the rest of the file untouched.
- Do not edit the launcher or the binary behind `impeccable hook` and `impeccable hook-before-edit` from this flow. Those are skill plumbing.
- When a user asks how far to trust the hook, say it runs the engine unsandboxed with the agent's environment and network access (in the Copilot cloud agent too, once `.github/hooks/impeccable.json` is committed), and that the launcher checks a downloaded engine against `<skill-base-dir>/scripts/engine-checksums.txt` before its first run; **never** call it sandboxed.
- The hook never blocks an edit; it emits a post-edit reminder. (A Cursor manifest still on the `preToolUse` gate can block a write until migrated.) Disabling stops the reminders.
- The hook is bundled with the Impeccable skill; install targets are in the table above.

## Failure modes

- If `.impeccable/config.json` or `.impeccable/config.local.json` is unreadable or malformed, the hook ignores that file and uses the remaining valid config/defaults. `impeccable hooks status` will show malformed files as ignored.
- If the user asks to "disable the hook" globally, lead with `hooks off` (persistent for this project; writes `hook.enabled: false` to config). `IMPECCABLE_HOOK_DISABLED=1` also works as a one-shot override that follows the shell.
