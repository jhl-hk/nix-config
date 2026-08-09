# commands.md — justfile and rebuild flow

All commands run from `/Users/jhl/Documents/nix-src/nix-config`. This mirrors `just --list`, grouped by use case.

**Agents suggest these; the user runs them.** The user also runs all `git` and `sops` operations.

## Contents

- [Daily](#daily)
- [Pre/post hooks](#prepost-hooks)
- [Maintenance](#maintenance)
- [Secrets](#secrets)
- [Dev shell](#dev-shell)
- [What is deliberately absent](#what-is-deliberately-absent)

## Daily

| Command | What it does |
|---|---|
| `just rebuild` | `sudo darwin-rebuild switch --flake .#$(hostname)`. Wrapped by `rebuild-pre` and `rebuild-post` (see below). The everyday command. |
| `just switch` | Alias for `rebuild`. Exists because the `sysnew` zsh alias and muscle memory both use it. |
| `just build` | Build the closure without activating. Runs `rebuild-pre` only — no point checking sops on a dry run. |
| `just rebuild-trace` | `switch` with `--show-trace`. For debugging evaluation errors. |
| `just rebuild-full` | `rebuild` then `check`. Slow; use before pushing. |
| `just rebuild-update` | `update` then `rebuild`. |
| `just check [ARGS]` | `nix flake check --all-systems --show-trace`. Because the `checks` output maps in every host's `.system` derivation, this **really builds all three Macs** — it is not just a type check. |
| `just diff` | `git diff ':!flake.lock'`, so input-update churn doesn't drown the signal. |

`hostname` is a justfile variable evaluated as `` `hostname` ``, so `just rebuild` always targets the machine you're on. There is no host argument — to build another machine's config use `nix build .#darwinConfigurations.<Name>.system` directly.

## Pre/post hooks

`rebuild`, `rebuild-trace` declare `rebuild-pre && rebuild-post`; `build` declares only `rebuild-pre`.

**`rebuild-pre`** depends on `update-nix-secrets` and `llm-models-soft` (in that order — the model fetch decrypts the key that `update-nix-secrets` just pulled), then runs:

```
git add --intent-to-add .
```

That line is not cosmetic. Flake source tracking **ignores untracked files entirely**, so a newly created `.nix` file is invisible to evaluation until it's at least intent-to-added. This is the single most common "my new module did nothing" cause. `--intent-to-add` lifts the file into the index without staging its contents, so it doesn't disturb a planned commit.

**`update-nix-secrets`** does `git -C ../nix-secrets fetch`, then `git rebase` with failures swallowed (`|| true` — a dirty or diverged secrets checkout still lets the rebuild proceed), then `nix flake update nix-secrets --timeout 5`. Guarded by a `[ -d ../nix-secrets ]` check.

**`llm-models-soft`** runs `llm-models` and swallows its exit code, printing a warning instead. `llm-models` on its own is strict — a 401, an empty response, or a missing `llm.api_key` all abort — and that is right when you run it deliberately. As a pre-hook the opposite is right: no network, no age key, or a 502 must not block a switch, and the committed `models.json` is a perfectly valid (if stale) list to build against. It also exports `JUST_LLM_MODELS_IN_REBUILD=1`, which suppresses `llm-models`'s per-model listing and its "Next: just rebuild" footer.

**`rebuild-post`** runs `check-sops`.

## Maintenance

| Command | What it does |
|---|---|
| `just update` | `nix flake update` + `brew update && brew upgrade`. |
| `just clean` | `sudo nix-collect-garbage -d` + `mo clean` (the `mole` disk cleaner from Homebrew). |
| `just fmt` | `nix fmt` — alejandra over the tree. |
| `just check-beta` | Reads `sw_vers` and the SoftwareUpdate `CatalogURL`; reports whether this Mac is on a seed catalog and therefore whether `darwinHomebrew.macosBeta` should be set. Nix evaluates purely and cannot detect this, which is why it has to be declared per host. |
| `just llm-models` | GETs `/v1/models` with the key decrypted straight out of `shared.yaml` (no rebuild needed first) and writes the sorted, deduplicated id list to `home/jhl/common/core/llm/models.json`, which `home/jhl/common/core/llm.nix` `readFile`s. Flake evaluation has no network, so the list cannot be fetched at build time — generating a file keeps it declarative: in git, diffable, revertable. **Already runs on every `just rebuild`** via `llm-models-soft`; run it by hand to see the full list, or to get the real error when the automatic refresh is quietly warning. |

## Secrets

These touch `../nix-secrets`. **Agents must not run any of them.**

| Command | What it does |
|---|---|
| `just age-key` | `nix run nixpkgs#age -- age-keygen`. Prints a fresh key to stdout; does not write a file. |
| `just sops-edit FILE` | Opens `../nix-secrets/secrets/<FILE>.yaml` in `sops`, e.g. `just sops-edit shared`. Sets `SOPS_AGE_KEY_FILE` if unset. |
| `just rekey` | Runs `sops updatekeys -y` over every `secrets/*.yaml` so each is re-encrypted to the current recipient list. Run **after** editing `.sops.yaml`. No-ops cleanly when no secrets exist yet. Reminds you to commit+push. |
| `just check-sops` | Reads the host's declared `sops.secrets` names and asserts each `/run/secrets/<name>` exists and is non-empty. Exits 0 with "skipped" when nothing is declared. Runs automatically as `rebuild-post`. |
| `just verify-sops [EXPECT]` | End-to-end canary check. Requires `hosts/common/optional/darwin/sops-canary.nix` imported and `canary/value` present in `shared.yaml`. |

### Where sops failures show up

Two paths, unequal visibility:

- **Switch time** — `system.activationScripts.postActivation`. `/run/current-system/activate` starts with `set -e` and the install script is inlined into it, so a decryption failure **aborts the switch with an error**. This is loud; you will not miss it.
- **Boot time** — `launchd.daemons.sops-install-secrets` (`RunAtLoad = true`), which re-creates secrets because `/run` is volatile. Output goes to launchd logs, not a terminal.

`just verify-sops` covers both: it checks the raw secret, the template substitution, permissions, and then `launchctl kickstart -k system/org.nixos.sops-install-secrets` to exercise the boot path.

## Dev shell

`nix develop` enters `shell.nix`: `just`, `alejandra`, `deadnix`, `sops`, `age`, `ssh-to-age`, `jq`, `yq-go`, `gum`.

The `shellHook` exports `SOPS_AGE_KEY_FILE=$HOME/.config/sops/age/keys.txt`, warns in yellow if that file is missing (activation will fail without it once any secret is declared), and prints `just --list`.

`sops` and `age` live here rather than in `hosts/` deliberately — no reason to install them on every machine just to edit a secret occasionally.

## What is deliberately absent

This repo has no NixOS machines yet, so there is **no** `spawn.sh`, `provision-nixos.sh`, `rebuild.sh`, `deploy.nix`, deploy-rs, disko, `nixos-anywhere`, ISO builder, or attic push recipe. Do not reference them or invent them. If a Linux host is added later, those become real work items, not existing infrastructure.

**There is no CI.** No `.github/` directory, no GitHub Actions workflow, no deploy key on `jhl-hk/nix-secrets`. A workflow existed briefly and was removed by choice — building three full Darwin closures on a hosted macOS runner was not worth the minutes, and it needed an SSH deploy key just to resolve the private `nix-secrets` input. `just check` is the pre-push gate and it runs locally. Do not add a workflow back without being asked.

There is also no `checks.nix` / pre-commit-hooks wiring — the `checks` flake output is built inline in `flake.nix` from `darwinConfigurations`.
