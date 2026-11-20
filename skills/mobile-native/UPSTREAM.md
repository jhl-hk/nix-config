# Upstream

| | |
|---|---|
| Source | https://github.com/emilkowalski/skills — `skills/mobile-native/` |
| Commit | `f7ce8c02d6e3c8f0d980a44c57bcc41a40254349` |
| License | MIT |

## Local changes

- Description rewritten to triggers; boundary points to animate, apple-design.
- Removed the canned initial response and persona; Operating Posture folded into Overview and When to Use.
- Removed references to deleted skills (review-animations, animate-expo).
- Tone section folded into Output.
- Hard Rules 4 (never disable zoom) and 5 (test on hardware) removed as repeats: the zoom rule and its "accessibility failure" reason live in §4 and Common Mistakes; the hardware steps (Web Inspector, Chrome remote debugging) live in §11.
- Sections renamed to the standard shape: Symptom Table → Quick Reference, The Fixes → Implementation, Never Ship → Common Mistakes.
- §5 press timing points to the animate skill instead of carrying 100–160ms ease-out.
- §10 adds the Astro `<head>` placement; the `viewport` export marked Next.js only.
- Curve tokens in code carry a literal fallback (copy-paste safe without animate's :root tokens).
