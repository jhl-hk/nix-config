# commands.md — justfile and rebuild flow

All commands run from `/Users/jhl/Documents/nix-src/nix-config`. Source: `justfile`, `scripts/rebuild.sh`, `shell.nix`. Recipes under [Secrets](#secrets) are user-operated (SKILL.md § Common Mistakes).

## Contents

- [Everyday](#everyday)
- [Hooks](#hooks)
- [scripts/rebuild.sh](#scriptsrebuildsh)
- [Maintenance](#maintenance)
- [LLM model lists](#llm-model-lists)
- [Secrets](#secrets)
- [Dev shell](#dev-shell)
- [Not in this repo](#not-in-this-repo)

The justfile exports `NIX_CONFIG := "extra-experimental-features = nix-command flakes"` to every recipe, so `just` works before the first switch (flakes are otherwise enabled by `/etc/nix/nix.conf` from nix-darwin/NixOS or `~/.config/nix/nix.conf` from `optional/nix/standalone.nix`). `extra-` appends; no-op on a switched machine.

## Everyday

| Command | Does | Hooks |
|---|---|---|
| `just` (`default`) | `just --list` | — |
| `just rebuild` | `scripts/rebuild.sh switch` | pre + post |
| `just switch` | alias for `rebuild` (zsh `sysnew` alias) | pre + post |
| `just build` | `scripts/rebuild.sh build` | pre |
| `just rebuild-trace` | `scripts/rebuild.sh switch --trace` | pre + post |
| `just rebuild-full` | `rebuild`, then `check` | — |
| `just rebuild-update` | `update`, then `rebuild` | — |
| `just deploy HOST [TARGET=HOST]` | `nix run nixpkgs#nixos-rebuild-ng -- switch --flake .#HOST --target-host TARGET --build-host TARGET --sudo`. Evaluates locally, builds and activates on the remote NixOS host. `TARGET` is an ssh destination; defaults to the `~/.ssh/config` alias named `HOST`. | pre |
| `just check [ARGS]` | `nix flake check --all-systems --show-trace ARGS`. Builds `darwin-<Host>` on aarch64-darwin, `nixos-<Host>` and `home-jhl-at-<Host>` on x86_64-linux; evaluates all. Pre-push gate; there is no CI. | — |
| `just diff` | `git diff ':!flake.lock'` | — |

## Hooks

**`rebuild-pre`** = `update-nix-secrets`, `llm-models-soft`, then `git add --intent-to-add .` (flake source tracking ignores untracked files; intent-to-add lists them without staging content).

**`update-nix-secrets`**: if `../nix-secrets` exists, `git fetch` and `git rebase` there (rebase failure ignored); then `nix flake update nix-secrets --timeout 5`. Runs before `llm-models-soft`, so the model fetch uses the freshly pulled key.

**`llm-models-soft`**: runs `llm-models` with `JUST_LLM_MODELS_IN_REBUILD=1` (suppresses the model listing and "Next: just rebuild"); on failure prints `⚠️  model list not refreshed, continuing with the committed models.json` and continues.

**`rebuild-post`** = `check-sops`.

## scripts/rebuild.sh

`scripts/rebuild.sh [switch|build] [--trace] [HOSTNAME]`. Default action `switch`, default host `$(uname -n)`. Running it directly skips the hooks.

**Lane selection:**

| Condition | Lane | Host dir | Target |
|---|---|---|---|
| `uname -s` = `Darwin` | darwin | `hosts/darwin/<Host>` | `darwinConfigurations.<Host>` |
| `Linux` and `/etc/NIXOS` exists | nixos | `hosts/nixos/<Host>` | `nixosConfigurations.<Host>` |
| `Linux` otherwise | home | `hosts/home/<Host>` | `homeConfigurations."$(id -un)@<Host>"` |
| anything else | refused | — | — |

A host with no `hosts/<lane>/<Host>/` directory is rejected with the list of known hosts in that lane.

**Activation, in order of preference:**

| Lane | 1st | 2nd | Fallback |
|---|---|---|---|
| darwin | `nh darwin <action> . --hostname <Host>` | `sudo darwin-rebuild <action> --flake .#<Host>` | `nix build .#darwinConfigurations.<Host>.system`, then `sudo ./result/sw/bin/darwin-rebuild` |
| nixos | `nh os <action> . --hostname <Host>` | `sudo nixos-rebuild <action> --flake .#<Host>` (sets `NIX_CONFIG` for flakes) | — |
| home | `nh home <action> . -c <user>@<Host> -b backup` | `home-manager <action> --flake .#<user>@<Host> -b backup` | `nix build .#homeConfigurations."<user>@<Host>".activationPackage`, then `HOME_MANAGER_BACKUP_EXT=backup ./result/activate` (switch only) |

- Every path passes `--option eval-cache false`: the `llm/*.json` lists are skip-worktree, so a refresh is invisible to the dirty-tree eval cache key.
- `nh` elevates itself and is never run under sudo. `sudo` is used for `switch` only.
- `--trace` adds `--show-trace`.
- `nh` comes from `home/jhl/common/core/nh.nix`, which also sets `NH_FLAKE`.
- The home lane never uses sudo. `-b backup` matches `backupFileExtension = "backup"` on the system lanes.

**Darwin bootstrap** (before activation): no Xcode CLT → runs `xcode-select --install` and exits (re-run after); no `/opt/homebrew/bin/brew` → installs Rosetta 2 on arm64, then Homebrew (nix-darwin runs `brew bundle` but never installs brew). Bootstrap builds pass `--extra-experimental-features "nix-command flakes"` instead of writing `~/.config/nix/nix.conf`, which would outrank nix-darwin's `/etc/nix/nix.conf`.

The script targets bash 3.2 (`/bin/bash` on a fresh Mac): no `${var^^}`, no `"${arr[@]}"` on a possibly empty array under `set -u`.

## Maintenance

| Command | Does |
|---|---|
| `just update` | `nix flake update`; on Darwin also `brew update && brew upgrade`. |
| `just clean` | `nix-collect-garbage -d` as the user (home-manager and profile generations), then `sudo nix-collect-garbage -d`. Darwin: `mo clean`. Arch (non-NixOS Linux): `mo clean`, `paru -Sc`, `paru -c`. |
| `just fmt` | `nix fmt` (alejandra). |
| `just check-beta` | Darwin only. Applies the `modules/hosts/darwin/homebrew/mas.nix` rule (`^[0-9]+[A-Z][5-9][0-9]{3}[a-z]?$` on `sw_vers -buildVersion`) and reports whether `masApps` install on the next switch; also prints seed-programme enrollment, which the rule ignores. Keep both regex copies in step. |

## LLM model lists

| Command | Does |
|---|---|
| `just llm-models-one SECRET HOST OUT` | Decrypts `SECRET.api_key` from `../nix-secrets/secrets/shared.yaml` with `sops -d --extract`, GETs `https://HOST/v1/models`, writes the sorted unique ids to `OUT`. Fails on missing `shared.yaml`, missing key, fetch error, or 0 models (existing file kept). |
| `just llm-models` | Runs `llm-models-one` for each gateway, continuing past failures; writes `active.json`; exits non-zero only if every gateway failed. |

Gateways (preference order):

| Secret | Host | Output |
|---|---|---|
| `llm` | `llm.jianyuelab.net` | `home/jhl/common/core/llm/models.json` |
| `llm_api` | `llm-api.jianyuelab.net` | `home/jhl/common/core/llm/models-api.json` |

- `active.json` = `{ apiUrl, apiKeyFile, models }` of the first gateway that refreshed (`apiKeyFile` = `/run/secrets/<secret>/api_key`); the editors read it.
- `git update-index --skip-worktree home/jhl/common/core/llm/*.json` runs first: the files stay tracked (flake eval needs them) but refreshes are hidden from `git status` and not committed.
- Consumed by `home/jhl/common/core/llm.nix` via `readFile`. Flake evaluation has no network, so the list is generated here.

## Secrets

| Command | Does |
|---|---|
| `just age-key [OUT]` | No `OUT`: `nix shell nixpkgs#age --command age-keygen` to stdout. With `OUT`: refuses to overwrite, creates the parent dir (0700), writes the key, `chmod 600`, prints the public key for `.sops.yaml`. |
| `just sops-edit FILE` | Opens `../nix-secrets/secrets/FILE.yaml` with `nix run nixpkgs#sops` from the nix-secrets root. `SOPS_AGE_KEY_FILE` defaults to `~/.config/sops/age/keys.txt`; fails if missing. Creates `secrets/`. Prints the commit/push + `just update-nix-secrets` reminder. |
| `just rekey` | `sops updatekeys -y` over every `secrets/*.yaml` after `.sops.yaml` changes; skips when none exist. |
| `just check-sops` | Darwin only (skips on any Linux). Lists `darwinConfigurations.$(uname -n).config.sops.secrets` names and asserts each `/run/secrets/<name>` is non-empty; skips when none are declared. |
| `just verify-sops [EXPECT=sops-pipeline-ok]` | Darwin only. End-to-end canary check. Preconditions: `secrets/shared.yaml` with `canary.value`, and `hosts/common/optional/darwin/sops-canary.nix` restored from git history and imported by the host (the recipe prints the restore command). Then checks the raw secret, template substitution in `~/.sops-canary`, target permissions (`stat -L`), and the launchd boot path via `launchctl kickstart -k system/org.nixos.sops-install-secrets`. |

Restore the canary module:

```bash
p=hosts/common/optional/darwin/sops-canary.nix
git show "$(git rev-list -n1 HEAD -- "$p")^:$p" > "$p"
```

Failure visibility of each sops path: `nix-secrets.md` § Failure visibility.

## Dev shell

`nix develop` → `shell.nix`: `just`, `alejandra`, `deadnix`, `sops`, `age`, `ssh-to-age`, `jq`, `yq-go`, `gum`. `shellHook` exports `SOPS_AGE_KEY_FILE=$HOME/.config/sops/age/keys.txt`, warns if it is missing, and runs `just --list`.

## Not in this repo

- No CI: no `.github/`, no workflow, no deploy key on `jhl-hk/nix-secrets`. Do not add one unless asked.
- No deploy-rs, disko, `nixos-anywhere`, ISO builder, attic push, `checks.nix` or pre-commit hooks. Remote NixOS activation is `just deploy`.
- `scripts/rebuild.sh` is the only script. No git tag on switch.
