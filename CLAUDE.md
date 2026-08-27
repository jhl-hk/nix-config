# CLAUDE.md

nix-darwin + home-manager flake, one user (`jhl`), three machines — all Macs — on one live lane:

- **nix-darwin** — `jhlsMacBookPro`, `jhlsMacBookAir`, `SeandeMac-Studio`. Host dir `hosts/darwin/<Host>/`, output `darwinConfigurations.<Host>`.
- **standalone home-manager** — no machines right now. Host dir `hosts/home/<Host>/`, output `homeConfigurations.jhl@<Host>`. **No system configuration exists on this lane**: no `hosts/common/core`, no `environment.systemPackages`, no sops. Anything needing root belongs to the distro's package manager.

  `jhlsArchLinux` was the one machine here and has been removed; `hosts/home/` is now a `.gitkeep` skeleton like `hosts/nixos/`. The lane's machinery — `mkHomeHost`, `lib.custom.evalHostSpec`, the Linux branch of `scripts/rebuild.sh`, `home/jhl/common/core/linux.nix` — is all still in place, so a Linux box returns by adding two files and nothing else. The division of labour that lane settled on (nix owns CLI tools, dotfiles and fonts; GUI apps and anything dlopen'd into another process stay with the distro) is worth recovering from git history before widening it.

A third lane, NixOS (`hosts/nixos/`), is an unused skeleton — don't mistake it for the standalone lane.

Private data lives in the sibling `../nix-secrets`, consumed as a flake input.

## Read this first

A full operating manual already exists at `claude/skills/nix-config/SKILL.md`, with deep references under `claude/skills/nix-config/references/`:

| File | Covers |
|---|---|
| `recipes.md` | **Main reference.** Decision tree + file templates for every "add X" task |
| `architecture.md` | flake outputs, `lib.custom`, auto-import vs cherry-pick, the two `lib` plumbing paths |
| `hostspec.md` | Every `hostSpec` option, its type, and which file sets it |
| `nix-secrets.md` | nix-secrets schemas, `.sops.yaml`, consumption patterns |
| `commands.md` | Full `justfile` catalog and the rebuild flow |

Invoke the `nix-config` skill instead of re-deriving the architecture. `README.md` covers the same ground for humans. **This file only carries what always applies, regardless of task.**

## Language

Everything is English: comments, option `description`s, `assertion` messages, `echo`/`printf` text, and docs. Keep it that way.

One deliberate exception, do not "fix" it: the `NSUserDictionaryReplacementItems` entry in `home/jhl/common/core/darwin/keyboard.nix` expands `msd` to a Chinese phrase. That is user data, not prose — translating it changes behaviour.

## Secrets are user-operated

Never run `sops`, never edit `.sops.yaml`, never generate age keys, never run `just rekey`, and never edit ciphertext under `../nix-secrets/secrets/`.

The correct move is: write the Nix that references `sops.secrets."<path>"`, state the exact YAML key path and file, then stop and hand it to the user. Adding a secret that does not exist yet should also add an assertion that names the missing key — see `modules/hosts/darwin/omni/default.nix` for the pattern (sops leaves key names in cleartext, so `lib.hasInfix "<key>:" (builtins.readFile sopsFile)` is a cheap eval-time guard that beats an opaque activation-time failure).

## Before claiming anything works

- **New files need `git add --intent-to-add .`** Flake source tracking ignores untracked files entirely, so a newly created `.nix` file silently has no effect — evaluation succeeds while your change does nothing. `just rebuild` runs this via `rebuild-pre`; when evaluating by hand, run it yourself first.
- **Evaluate, don't assume.** `nix eval .#darwinConfigurations.<host>.config.system.build.toplevel.drvPath` catches assertions and type errors; on the standalone lane it is `nix eval .#homeConfigurations.\"jhl@<host>\".activationPackage.drvPath`. `just check` builds every machine and is the gate before pushing. There is no CI.
- **Check the generated artifact, not just that it evaluates.** For anything that produces a file, build and read it — e.g. `nix build .#darwinConfigurations.<host>.config.home-manager.users.jhl.xdg.configFile."<path>".source` then `cat` it. The standalone equivalent drops the middle: `.#homeConfigurations."jhl@<host>".config.xdg.configFile."<path>".source`.
- **Format:** `just fmt`, or `nix run nixpkgs#alejandra -- --check <files>`.

## Failure modes that are silent

These break without an error, which makes them the expensive ones:

- `hosts/common/optional/**` is **not** auto-imported. Creating a file there does nothing until a host names it in `imports`. (`modules/**` *is* auto-imported by `scanPaths`.)
- `lib.custom.relativeToRoot` takes a **string**, not a path literal.
- `sops.templates.<x>.path` and `sops.secrets.<x>.path` land a **symlink** into `/run/secrets`. Anything that writes through it is wiped at the next activation, and `/run` is volatile across reboots.
- Homebrew runs `onActivation.cleanup = "zap"`. Removing a brew from `apps.nix` uninstalls it; a manual `brew install` is temporary.
- `home.file` / `xdg.configFile` produce **read-only** store symlinks. Do not manage a config file that its own tool writes back (Claude Code's `settings.json`, `opencode plugin`, Zed's UI-written settings).
- `programs.zed-editor` runs with `mutableUserSettings = true`, a **one-way merge**: removing a key from Nix does not remove it from the on-disk `settings.json`.
- `hosts/home/<Host>/default.nix` is **not a NixOS module** — it is `evalModules`'d against `modules/common/host-spec.nix` alone. It may set `hostSpec` and nothing else. Keep `hosts/common/core/host-spec.nix` free of `imports` and other options for the same reason: both lanes evaluate it, only one has a system scope around it.
- Cross-platform home files really are cross-platform now. A Darwin-only path (`/opt/homebrew`, `/etc/profiles/per-user`, `launchd`, `targets.darwin`) in `home/jhl/common/core/*.nix` reaches Arch too. Put it in `common/core/darwin.nix` or `common/core/darwin/`.

For the rest — `system.stateVersion` types, `mkOrder 1100`, `lib` in `extraSpecialArgs` — see the README's "Traps" section and `architecture.md`.

## Changing nix-secrets

It is a locked remote input: local edits are invisible to this flake until pushed. After changing it, the user must `git push` there, then `just update-nix-secrets` here. Say so explicitly rather than assuming a change took effect.
