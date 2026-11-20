# Upstream

All four sources ship the same MIT `LICENSE` text (Copyright (c) 2026 Emil Kowalski); one copy is kept.

| | |
|---|---|
| Source | https://github.com/emilkowalski/skills — `skills/improve-animations/` |
| Commit | `f7ce8c02d6e3c8f0d980a44c57bcc41a40254349` |
| License | MIT (`LICENSE`) |

| | |
|---|---|
| Source | https://github.com/emilkowalski/skills — `skills/review-animations/` |
| Commit | `f7ce8c02d6e3c8f0d980a44c57bcc41a40254349` |
| License | MIT (`LICENSE`) |

| | |
|---|---|
| Source | https://github.com/emilkowalski/skills — `skills/find-animation-opportunities/` |
| Commit | `f7ce8c02d6e3c8f0d980a44c57bcc41a40254349` |
| License | MIT (`LICENSE`) |

| | |
|---|---|
| Source | https://github.com/emilkowalski/skills — `skills/remove-animations/` |
| Commit | `f7ce8c02d6e3c8f0d980a44c57bcc41a40254349` |
| License | MIT (`LICENSE`) |

## Local changes

- Merged review-animations, find-animation-opportunities and remove-animations as Review, Find and Remove modes beside Audit; their directories are removed.
- Dropped `disable-model-invocation` (from review-animations); the merged skill is model-invocable.
- SKILL.md restructured to the README shape; description rewritten to triggers for all four modes plus boundaries to animate, animation-performance, accessible-animation.
- Removed the canned initial responses, "senior design engineer" persona prose and workflow-origin notes.
- One gate for all modes, merged from find's four questions and remove's decision tree (first match decides; columns for new candidates vs existing animations).
- One severity table: audit's HIGH/MEDIUM/LOW with review's escalation triggers sorted into it. Review's ten standards replaced by AUDIT.md categories 1–7, which state the same rules.
- Review verdict: Approve only when all approval criteria hold, otherwise Block (upstream left the gap between Block and Approve undefined).
- review-animations `STANDARDS.md` merged into `AUDIT.md` (springs, interruptibility and asymmetric-timing code, WAAPI, transforms and clip-path, gestures, stagger, Sonner cohesion note, debugging); the file is removed.
- find-animation-opportunities hunt list moved to AUDIT.md §8; remove-animations hunt list moved to AUDIT.md §1.
- Sweep greps of all four skills unified in Recon.
- PLAN-TEMPLATE.md: feel-check note points to AUDIT.md "Debugging feel".
- Dropped remove-animations' remark that agents add motion by default (motivation; the gate covers the behaviour).
- AUDIT.md §2 easing decision order, curve tokens and duration table, and §4 spring configs, replaced by `**REQUIRED BACKGROUND:** animate`; the audit hunting rules (what to flag) stay. §8 gesture-seam spring cites animate.
- AUDIT.md §5 `--swipe-amount` code reduced to one rule with a pointer to animation-performance.
- SKILL.md: replacement curves, durations and spring configs cite animate; AUDIT.md keeps every other value.
- Remove mode (rules, reduction table, removal hazards, cleanup, workflow, report format) moved verbatim from SKILL.md to `references/remove-mode.md`; SKILL.md keeps a two-line pointer and a Files row.
- "Make this feel more alive" trigger dropped from the description and the Find row (animate owns it).
- Body `Not for:` list removed (it drifted from the description); its "use a general code review skill" became a description boundary naming requesting-code-review; "Find mode only proposes motion; implementation goes through a plan" moved to Find mode.
- Gate: the purposes list and the Raycast line replaced by a pointer to animate, which absorbed the purpose examples.
- Remedial hierarchy steps 3–4 point at the Findings rows instead of restating them; Findings notes that the Severity table decides what to flag.
- Built-in `ease-out` in prescribed fixes replaced by `var(--ease-out)` (SKILL.md Findings and Find examples; AUDIT.md §3 press feedback, §4 asymmetric timing, §8 feedback gaps).
- AUDIT.md: intro value rule reworded ("Curves, durations and springs: copy from animate. Every other value: copy from here."); copies of animate collapsed to hunt rules plus "Fix: animate RECIPES › …" pointers — §1 frequency table, §4 toast `@starting-style` and legacy mount flag, §4 drag details, §5 Motion 14.2 snippet, §5 WAAPI snippet, §6 reduced-motion/hover code, §7 stagger snippet, §7 blur crossfade.
- PLAN-TEMPLATE.md and SKILL.md Review mode step 2: value source split (curves, durations, springs from animate; everything else from AUDIT.md), matching the Findings rule.
- Curve tokens in code carry a literal fallback (copy-paste safe without animate's :root tokens).
