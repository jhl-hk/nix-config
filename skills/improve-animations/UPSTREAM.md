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
