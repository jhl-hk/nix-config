---
name: impeccable
description: "Use when the user wants to design, redesign, shape, critique, audit, polish, simplify, harden, animate, or otherwise improve a frontend interface: websites, landing pages, dashboards, product UI, components, forms, settings, onboarding, empty states, and native iOS or Android screens. Handles UX review, hierarchy, layout, typography, color, motion, UX copy, accessibility, responsive behavior, edge cases, and capturing or documenting design systems (DESIGN.md, tokens). Also for making bland UI bolder, loud UI quieter, or ambitious visual effects. Not for backend-only or non-UI tasks. Not for adding or tuning a single animation or interaction (use animate, micro-interaction); not for janky or dropped-frame motion (use animation-performance); not for worst-case data stress tests (use break-ui); not for mobile-web viewport quirks like 100vh, notch or input zoom (use mobile-native); not for integrating @jianyuelab/tokens or @jianyuelab/ui (use jianyuelab-ui); not for building a marketing or company site from scratch (use design-taste-frontend)."
version: 4.8.0
user-invocable: true
argument-hint: "[shape · audit|critique · animate|bolder|colorize|delight|layout|overdrive|quieter|typeset · adapt|clarify|distill · harden|onboard|optimize|polish · init|document|extract|live|generate] [target]"
license: Apache 2.0
---

# Impeccable

## Overview

Design and refine frontend interfaces as a design director would: production-grade code, a clear point of view, and craft scaled to what the surface's visitor needs. Finish the job; the deliverable is complete except assets the user must provide.

## When to Use

- Existing product UI: critique, audit, refinement (bolder, quieter, distill, polish, harden, adapt), copy, onboarding, performance.
- New surfaces or a replacement visual world inside a product, through `new-work`.
- Capturing a design system (PRODUCT.md, DESIGN.md, tokens) or iterating visually in the browser (`live`, `generate`).
- Native iOS, Android or adaptive screens (commands swap in their native references).

Not for:

| Request | Use |
|---|---|
| A single animation, transition or hover/press interaction | animate, micro-interaction |
| Janky, stuttering, dropped-frame motion | animation-performance |
| Worst-case data: long text, emoji, empty, huge counts | break-ui |
| Mobile web quirks: 100vh, notch, tap highlight, input zoom | mobile-native |
| `@jianyuelab/tokens` / `@jianyuelab/ui` integration | jianyuelab-ui |
| Building a marketing or company site from scratch | design-taste-frontend |

When a project uses `@jianyuelab/tokens` or `@jianyuelab/ui`, defer to jianyuelab-ui for tokens and components. Usual stack: Astro with Vue or React islands, Tailwind (v4 `@theme` first), Vite, bun; check `package.json` first.

## Core Pattern

### How to design

- **The brief wins.** Honour pinned aesthetics, eras, materials, fonts and palettes even when they conflict with a saturated-pattern warning. Redirecting a clear brief toward your taste is failure.
- **Refinement preserves; redesign replaces.** Refinement keeps the incumbent identity, behaviour, copy and everything outside scope. Ask before replacing factual copy or adding claims. Redesign keeps product truth, content, function, native affordances and constraints, but treats the old look as evidence and anti-reference; choose a replacement world in new-work and replace DESIGN.md. Never split the difference into polish on the discarded look.
- **Visual authority is evidence, not a filename.** Missing DESIGN.md alone does not make a project greenfield; new-work decides whether to preserve, expand or replace the incumbent world.
- **Loaded symbols stay out of the decoration.** A subject's world does not license emblems tied to militarism, supremacy or hate movements as motifs, badges or ornament (the Rising Sun flag's rays, the Confederate battle flag, Nazi-era insignia and their stylised variants); use that world's neutral forms. Content that documents such a symbol as fact stays as it is.
- **Verify by looking** at the rendered result at the sizes it ships at. Batch the checks: fix what one look shows before looking again.
- **Read [craft-floor.md](reference/craft-floor.md) immediately before any UI edit**, including small refinements, after analysis and direction are resolved. Skip it for planning-only work.
- **Every refinement command ends with `polish`** as the final pass, unless the command was `polish`.

### Modes

The mode names what the visitor's success looks like on this surface. It sets the ambition: Persuade and Experience get full commitment; on Operate and Read, ambition shows as precision and restraint, and familiar patterns earn their place.

| Mode | Visitor | Surfaces | Priority | Rules |
|---|---|---|---|---|
| Persuade | decides and acts | landing, marketing, campaigns, pricing | earn attention and action; real imagery when the brief needs it; follow the committed world, not category habit | [mode-persuade.md](reference/mode-persuade.md) |
| Operate | completes a task | app UI, dashboards, editors, admin, settings, tools | scanability, consistency, native expectations and the real usage scene outrank expression; brand lives in precise details | [mode-operate.md](reference/mode-operate.md) |
| Read | understands something | docs, articles, guides, help, changelogs | structure for comprehension, then make reading worth staying for | [mode-read.md](reference/mode-read.md) |
| Experience | is inside the work | portfolios, galleries, showcases | the artifact leads from the first viewport; the interface recedes | [mode-persuade.md](reference/mode-persuade.md) |

Choose the mode from the requested surface, not the product, and persist it only in that surface brief. A tool's landing page is Persuade; a fashion house's documentation is Read; a docs index is Read.

## Quick Reference

| Command | Category | Description | Reference |
|---|---|---|---|
| `shape [feature]` | Build | Plan UX/UI before writing code | [shape.md](reference/shape.md) |
| `init` | Build | Capture durable product context in PRODUCT.md | [init.md](reference/init.md) |
| `document` | Build | Generate DESIGN.md from existing project code | [document.md](reference/document.md) |
| `extract [target]` | Build | Pull reusable tokens and components into the design system | [extract.md](reference/extract.md) |
| `critique [target]` | Evaluate | UX design review with heuristic scoring | [critique.md](reference/critique.md) |
| `audit [target]` | Evaluate | Technical quality checks (a11y, perf, responsive) | [audit.md](reference/audit.md) · native: [audit.native.md](reference/audit.native.md) |
| `polish [target]` | Refine | Final quality pass before shipping | [polish.md](reference/polish.md) |
| `bolder [target]` | Refine | Amplify safe or bland designs | [bolder.md](reference/bolder.md) |
| `quieter [target]` | Refine | Tone down aggressive or overstimulating designs | [quieter.md](reference/quieter.md) |
| `distill [target]` | Refine | Strip to essence, remove complexity | [distill.md](reference/distill.md) |
| `harden [target]` | Refine | Production-ready: errors, i18n, edge cases | [harden.md](reference/harden.md) |
| `onboard [target]` | Refine | First-run flows, empty states, activation | [onboard.md](reference/onboard.md) |
| `animate [target]` | Enhance | Purposeful motion tied to the visual world | [animate.md](reference/animate.md) |
| `colorize [target]` | Enhance | Strategic colour for monochromatic UIs | [colorize.md](reference/colorize.md) |
| `typeset [target]` | Enhance | Typography hierarchy and fonts | [typeset.md](reference/typeset.md) |
| `layout [target]` | Enhance | Spacing, rhythm and visual hierarchy | [layout.md](reference/layout.md) |
| `delight [target]` | Enhance | Personality and memorable touches | [delight.md](reference/delight.md) |
| `overdrive [target]` | Enhance | Push past conventional limits | [overdrive.md](reference/overdrive.md) |
| `clarify [target]` | Fix | UX copy, labels and error messages | [clarify.md](reference/clarify.md) |
| `adapt [target]` | Fix | Devices and screen sizes | [adapt.md](reference/adapt.md) · native: [adapt.native.md](reference/adapt.native.md) |
| `optimize [target]` | Fix | Diagnose and fix UI performance | [optimize.md](reference/optimize.md) |
| `live` | Iterate | Pick elements in the browser, iterate on alternatives | [live.md](reference/live.md) |
| `generate [n] [action] [element]` | Iterate | Variants of a named element to choose from in the live browser, no manual picking | [generate.md](reference/generate.md) |
| `pin <pin\|unpin> <command>` | Tooling | Create or remove a standalone `/<command>` shortcut | below |
| `hooks <on\|off\|status\|ignore-rule\|ignore-file\|ignore-value\|reset>` | Tooling | Manage the design detector hook | [hooks.md](reference/hooks.md) |
| `doctor` | Tooling | Report and repair drift in Impeccable artifacts | [doctor.md](reference/doctor.md) |

Aliases: `teach` = `init`. `craft` = an ordinary new-work request; it adds nothing.

Routing:

- **No argument:** read [routing.md](reference/routing.md) and present its context-aware menu; never auto-run a command.
- **Explicit or clearly implied command:** load its reference (native variant on native platforms) and follow it. Ask once if two commands fit.
- **Workflow or command-selection question:** read [Workflow questions](reference/routing.md#workflow-questions).
- **Otherwise:** general design work. A new surface or replacement world loads [new-work.md](reference/new-work.md); missing PRODUCT.md routes it through init first. A narrow refinement of existing code proceeds on the incumbent implementation as `impeccable context` directs, offering init afterward instead of blocking on it.
- `shape` owns task discovery, then enters new-work only for visual-world and surface-concept decisions.

## Implementation

`<skill-base-dir>` is the directory containing this SKILL.md. Substitute it before running any command in this skill or its references; it is not a shell variable. The launcher is `"<skill-base-dir>/scripts/impeccable" <verb>` (Windows shell without `sh`: `& "<skill-base-dir>/scripts/impeccable.cmd"`). It runs a self-contained engine binary that ships next to it or is downloaded once on first run; no Node or other runtime is required. Keep cwd at the user's project.

1. Run `"<skill-base-dir>/scripts/impeccable" context` once per session. Pass a named source file or route as `--target <path>`. It loads PRODUCT.md, DESIGN.md, the matching surface brief and native-platform guidance when applicable. Follow its directives and do not rerun it. After init writes PRODUCT.md, resume without rerunning it; init loads the native platform reference itself when it records `ios`, `android` or `adaptive`.
2. Load the playbook: the command's reference, or [new-work.md](reference/new-work.md) for a new surface or replacement visual world. Inspect the target and incumbent visual truth before editing. When the app cannot run, start from committed visual-regression goldens or screenshot fixtures; verify target and freshness against current tokens, CSS, components or assets, resolve conflicts, and compare theme/variant captures.
3. Read [craft-floor.md](reference/craft-floor.md) before the first UI edit.

**Launcher unavailable:** on refusal or failure, send a separate message before the next tool call: "Context loading did not run; I'll read the existing project context directly." Then read existing PRODUCT.md and DESIGN.md without inventing missing context, follow steps 2–3, and continue. Launcher failure alone blocks neither planning nor editing.

**Subagent roles:** dispatch a subagent with `reference/degraded/<role>.md` as its instructions (roles: finish-reviewer, documenter, asset-producer, manual-edit-applier). Run that file inline only when the harness cannot dispatch subagents.

**Pin / Unpin:** `"<skill-base-dir>/scripts/impeccable" pin <pin|unpin> <command>`. Report the result concisely; relay stderr verbatim on error.

**Hooks:** load [hooks.md](reference/hooks.md) when the user invokes `hooks` with any argument. The hook auto-runs the detector after UI file edits and surfaces findings.

**Doctor:** load [doctor.md](reference/doctor.md) when the user invokes `doctor` or asks what is out of date, stale or needs refreshing. Covers PRODUCT.md, DESIGN.md and its sidecar, config, surface briefs and the hook.

## Common Mistakes

| Mistake | Fix |
|---|---|
| Repairing drift as a side effect of a design task | Report a `CONTEXT_STALE` finding; act only when the user asks. Exception: a finding marked `auto`, which the next write to that file performs anyway. |
| Running doctor because `CONTEXT_STALE` appeared | `CONTEXT_STALE` is doctor's cheap subset; follow its own instructions in Setup output. |
| Auto-running a command from the no-argument menu | Recommend; the user confirms. |
| Treating missing DESIGN.md as greenfield | Inspect the incumbent implementation; new-work decides. |
| Polishing a look the user asked to replace | Redesign through new-work. |
| Editing UI without reading craft-floor | Read it before the first edit. |
