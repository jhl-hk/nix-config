# Upstream provenance

Vendored, not tracked as a flake input.

| | |
|---|---|
| Source | https://github.com/github/awesome-copilot — `skills/gdpr-compliant/` |
| Commit | `87ba8b1780d0e2655fc19fa3f8d4fc7879881744` |
| License | MIT (© GitHub, Inc. and contributors) |

## Why vendored

Every other third-party skill in this repo is a flake input, which keeps the
license with the source and makes `nix flake update` the whole update workflow.
This one is the exception: `github/awesome-copilot` is a 105 MiB checkout of
2833 files covering 100 Copilot plugins, and three of them are this skill.
Carrying that input would mean re-fetching 105 MiB on every machine on every
lock bump to track a leaf skill that is not part of an evolving set.

## Local changes

Two fixes; the body is otherwise upstream's verbatim.

1. `references/Security.md` → `references/security.md`. `SKILL.md` refers to it
   lowercase three times. macOS resolves either way, but the store path is read
   on the standalone Linux lane too, where the reference would 404.
2. Dropped the `references/operations.md` bullet from the reference list.
   Upstream ships no such file, so the line pointed the agent at nothing.

Re-check both when bumping the commit above.
