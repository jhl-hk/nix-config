---
name: nix-config
description: Use when working in ~/Documents/nix-src/nix-config or ../nix-secrets; when adding or editing a Darwin host, a NixOS host (DevEnv), a standalone home-manager Linux host (jhlsRogZephyrus, jhlsTokyoDesktop), a system module, a home-manager program or dotfile, a Homebrew brew/cask/masApp, a custom package, an overlay, or a sops secret (system or home-manager); when wiring hostSpec from nix-secrets; when touching hosts/, home/, modules/, lib/, pkgs/, overlays/, skills/, assets/, flake.nix, shell.nix, justfile or scripts/rebuild.sh; when running just rebuild, just deploy, just check, just llm-models, darwin-rebuild, nixos-rebuild, nh, home-manager switch, nix flake check or sops; when configuring omp (omp.nix, models.yml, nix.yml overlay, mcp.json, omp.mcpServers, mcpServers), agent instructions (AGENTS.md), skill deployment (skills.nix, ~/.agents/skills), llm providers or wakatime; when debugging hostSpec assertions, scanPaths imports that did not fire, a new file with no effect, system.stateVersion type errors, environment.systemPath ordering, `attribute 'hm' missing`, `attribute 'custom' missing`, "nix-darwin 26.05 with Nixpkgs 26.11", or sops secrets missing from /run/secrets. Not for writing skill content; use writing-skills.
---

# nix-config

## Overview

`/Users/jhl/Documents/nix-src/nix-config` is a public flake for one user (`jhl`) on six machines across three lanes; private data comes from the sibling flake `../nix-secrets`. Hosts are discovered from directories, modules are auto-imported, optionals are cherry-picked, and every module reads machine data from `hostSpec`.

The lane table (host dirs, outputs, machines), the silent failure modes and the secret rules are in this repo's `AGENTS.md`; this skill does not repeat them. Working from `../nix-secrets`, that file is not loaded: read it first. Every machine also has `home/jhl/<Host>.nix`. Per-lane builders (`mkDarwinHost` aarch64-darwin, `mkNixosHost` and `mkHomeHost` x86_64-linux): `references/architecture.md`.

## When to Use

- Any edit under this repo or `../nix-secrets/nix/`.
- Rebuilding, deploying, checking, or debugging an evaluation/activation failure.
- Configuring omp, MCP servers, agent instructions or skill deployment through Nix.

Not for: the content of a skill under `skills/` (writing-skills and `skills/README.md`); running `sops` or editing ciphertext (user-operated; AGENTS.md, `references/nix-secrets.md`).

## Core Pattern

| Layer | Path | Wired by |
|---|---|---|
| Host | `hosts/<lane>/<Host>/default.nix` | `readDir` in `flake.nix`; a new directory is a new machine |
| System core | `hosts/common/core/` (`default.nix` + `darwin.nix`/`nixos.nix`) | `flake.nix`, system lanes only |
| System optional | `hosts/common/optional/{darwin,nixos,common}/` | named in a host's `imports` |
| Modules | `modules/{common,home,hosts/{common,darwin,nixos}}/` | `lib.custom.scanPaths`; hosts set `<name>.enable` |
| Home | `home/jhl/<Host>.nix` → `common/core` (+ `darwin.nix`/`linux.nix`) + `common/optional/<cat>/` | `hosts/common/users/jhl/<platform>.nix` or `mkHomeHost` |
| Data bus | `modules/common/host-spec.nix` declares, `hosts/common/core/host-spec.nix` populates | system modules read `config.hostSpec`, home modules take a `hostSpec` argument |

Details: `references/architecture.md` (flake outputs, lib plumbing, platform siblings, merge order, agent tooling), `references/hostspec.md` (every field).

## Quick Reference

| Task | Recipe in `references/recipes.md` |
|---|---|
| System feature some hosts import, no options | 1 |
| System or home module with options | 2 |
| Package not in nixpkgs | 3 |
| Override a nixpkgs package | 4 |
| Home-manager program / dotfile | 5a–5d |
| Homebrew brew / cask / masApp | 6 |
| New Mac / standalone Linux / NixOS host | 7 / 7b / 7c |
| Secret on Mac or NixOS / on standalone Linux | 8 / 8b |
| Second user | 9 |
| MCP server for omp | 10 |
| Skill deployed to `~/.agents/skills` | 11 |

```
just rebuild            # switch this machine (lane from uname / /etc/NIXOS)
just build              # build only
just deploy HOST [TGT]  # switch a remote NixOS host over ssh
just check              # nix flake check --all-systems; builds every native machine
just fmt                # alejandra
just update             # nix flake update (+ brew on macOS)
just llm-models         # refresh gateway model lists
nix develop             # just alejandra deadnix sops age ssh-to-age jq yq-go gum
```

Full catalog and `scripts/rebuild.sh` behaviour: `references/commands.md`.

## Implementation

1. Pick the recipe from the table; read it in `references/recipes.md`.
2. Write the files. New file → `git add --intent-to-add .` (the flake ignores untracked files; `just rebuild`/`build`/`deploy` do it in `rebuild-pre`).
3. Evaluate the affected host:
   - darwin: `nix eval .#darwinConfigurations.<Host>.config.system.build.toplevel.drvPath`
   - NixOS: `nix eval .#nixosConfigurations.<Host>.config.system.build.toplevel.drvPath`
   - standalone: `nix eval .#homeConfigurations.\"jhl@<Host>\".activationPackage.drvPath`

   Then build and read any generated file, `just fmt`, and `just check` before pushing (AGENTS.md § Testing & QA).
4. Secret involved → name the YAML key and file, stop, hand off.

| Reference | Read when |
|---|---|
| `references/recipes.md` | before adding anything |
| `references/architecture.md` | something imports unexpectedly, a lib error, merge order, agent tooling |
| `references/hostspec.md` | reading or adding a `hostSpec` field |
| `references/nix-secrets.md` | anything touching `../nix-secrets`, sops, `agents/AGENTS.md` |
| `references/commands.md` | any `just` recipe or `scripts/rebuild.sh` question |

## Common Mistakes

AGENTS.md § Testing & QA (including its silent failure modes) and the secret rules in § Runtime/Tooling Preferences always apply (the full secret rules: `references/nix-secrets.md` § What agents must not do). The rows below are the rest.

| Mistake | Fix |
|---|---|
| Key removed from Nix stays in Zed `settings.json` | `programs.zed-editor` uses `mutableUserSettings = true`, a one-way merge; remove it from `settings.json` by hand. |
| `system.stateVersion` type error | Integer on Darwin (`6`), string on NixOS (`"26.05"`); standalone has only `home.stateVersion = "26.05"` (`home/jhl/common/core/default.nix`). Never bump without release notes. |
| `attribute 'hm' missing` | `lib` was put in `extraSpecialArgs`. Pass it via `specialArgs.lib` (system) or top-level `lib` of `homeManagerConfiguration` (standalone). See `architecture.md`. |
| `attribute 'custom' missing` in home-manager | `lib` defaulted to `pkgs.lib`; same fix as above. |
| "nix-darwin 26.05 with Nixpkgs 26.11" | Darwin hosts need `darwinLib` (from `nixpkgs-darwin`), not the unstable `lib`. |
| Homebrew ahead of Nix, or Xcode git wins | `environment.systemPath` needs `lib.mkOrder 1100`; not plain, not `mkAfter`. See `architecture.md`. |
| Generated file keeps source indentation | A `${...}` at column 0 inside `''` stops de-indent; build a single-line value (`home/jhl/common/core/darwin/ssh-agent.nix`). |
| Darwin eval fails on `group` | Gate Linux-only attrs: `lib.optionalAttrs pkgs.stdenv.isLinux { group = "wheel"; }`. |
| Host can't override a shared value | `lib.mkDefault` in shared layers, plain assignment in host files; `mkForce` in a shared file is a smell. |
| Home module reads `config.hostSpec` | Destructure `{ hostSpec, ... }`; `modules/common` is not imported into HM. |
| Module reads `inputs.nix-secrets.<x>` | Read `config.hostSpec.<x>`. Only `"${inputs.nix-secrets}/secrets/<file>.yaml"` as `sopsFile` (and `agents/AGENTS.md` as a source) may name the input. |
| NixOS-only setting in `home/jhl/common/core/linux.nix` | `linux.nix` loads on standalone hosts too; use `hosts/common/core/nixos.nix`. |
| `optional/nix/standalone.nix` imported on a Mac | Its `~/.config/nix/nix.conf` outranks nix-darwin's `/etc/nix/nix.conf`. Standalone hosts only. |
| `optional/sops/standalone.nix` on a Mac or NixOS host | System sops already provides the secrets there; standalone hosts only. |
| Standalone consumer reads `/run/secrets/...` | Doesn't exist there; repoint with `mkForce` in `sops/standalone.nix` (Recipe 8b). |
