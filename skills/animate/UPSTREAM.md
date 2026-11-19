# Upstream

| | |
|---|---|
| Source | https://github.com/emilkowalski/skills — `skills/animate/` |
| Commit | `f7ce8c02d6e3c8f0d980a44c57bcc41a40254349` |
| License | MIT (`LICENSE`) |

| | |
|---|---|
| Source | https://github.com/vercel-labs/open-agents — `.agents/skills/web-animation-design/` |
| Commit | `cf865e94de7729751c747171785b6ce57e7b178c` |
| License | MIT (`LICENSE-web-animation-design`) |

## Local changes

- Merged web-animation-design into this skill; its directory is removed.
- SKILL.md restructured to the README shape; description rewritten to triggers plus boundaries.
- Removed the canned initial response, operating-posture prose and references to deleted skills (review-animations, find-animation-opportunities, animate-expo, pick-ui-library).
- Added from web-animation-design: ease-out/ease-in-out curve families, paired-elements rule, duration scaling and ~20% faster exits, marketing vs product, React render-cycle and blur limits.
- web-animation-design `PRACTICAL-TIPS.md` moved to `references/practical-tips.md`, trimmed to tips not already in SKILL.md.
- Dropped from web-animation-design: the Before/After review-format rule (reviews belong to improve-animations); "disable all motion, no exceptions" reduced-motion rule (conflicts with "gentler, not zero"; accessible-animation owns it); claim that Motion `x` is never hardware accelerated (superseded by Motion 14.2); ASCII easing flowchart (duplicates the easing table); course URL `/learn/easing-curves`.
