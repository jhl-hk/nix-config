# Upstream

| | |
|---|---|
| Source | https://github.com/emilkowalski/skills — `skills/write-swift/` |
| Commit | `f7ce8c02d6e3c8f0d980a44c57bcc41a40254349` |
| License | MIT |

## Local changes

- Description rewritten to triggers.
- Removed the canned initial response; intro became Overview.
- Reshaped to the README C.1 sections: Overview, new When to Use (includes the Swift 6.1-or-earlier concurrency exclusion that was in Overview), Quick Reference (the hierarchy-of-defaults table, moved out of Overview), Implementation (§1–§16 demoted one heading level, `---` separators removed), Common Mistakes (the old end-of-file Quick Reference table; its Not column is the mistake).
- Common Mistakes dropped the rows the hierarchy table already states: data type, polymorphism, fixed-size buffer, deciding to optimize.
- Fixed the contradiction in the shared-model-class row: "non-`Sendable`, or `@MainActor`" → "non-`Sendable`; `nonisolated` to leave main", matching §4.
- The Swift 6.4 "unreleased" caveat is stated once, in Overview (merged with the §15 paragraph); §5, §9, §14 and §15 use only ⚠. Dropped the "as of August 2026" date.
- Cut filler: "Every rule below applies that.", "Value types are the default…", "the section agents get wrong most often", "Clarity at the point of use is the goal…", "Agents routinely write…", "Both of these were 100×+ regressions…", and the "same discipline as…" asides in §1 and §7.
- Rules kept once: single-threaded start (§3 progression step 1); profile-before-offload merged into §3 progression step 3 (§9 "Then profile" stays the profiling home); main-actor-by-default stays in §3, §6 and §16 point to it.
