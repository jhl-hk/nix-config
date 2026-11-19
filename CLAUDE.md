# CLAUDE.md

nix-darwin + NixOS + home-manager flake, one user (`jhl`), six machines on three lanes:

| Lane | Host dir | Output | Machines |
|---|---|---|---|
| nix-darwin | `hosts/darwin/<Host>/` | `darwinConfigurations.<Host>` | `jhlsMacBookPro`, `jhlsMacBookAir`, `SeandeMac-Studio` |
| standalone home-manager | `hosts/home/<Host>/` | `homeConfigurations."jhl@<Host>"` | `jhlsRogZephyrus`, `jhlsTokyoDesktop` |
| NixOS | `hosts/nixos/<Host>/` | `nixosConfigurations.<Host>` | `DevEnv` |

The standalone lane has no system configuration: no `hosts/common/core`, no `hosts/common/optional`, no `environment.systemPackages`. Root-level concerns belong to the distro. Secrets there go through home-manager sops (`home/jhl/common/optional/sops/standalone.nix`).

Private data lives in the sibling `../nix-secrets`, consumed as a flake input.

**Load the `nix-config` skill (`skills/nix-config/`) for any task here.** It holds the recipes, architecture, hostSpec, secrets and command references. This file carries only what always applies.

## Language

Everything is English: comments, option `description`s, `assertion` messages, `echo`/`printf` text, and docs.

Exception, do not "fix" it: the `NSUserDictionaryReplacementItems` entry in `home/jhl/common/core/darwin/keyboard.nix` expands `msd` to a Chinese phrase. It is user data; translating it changes behaviour.

## Secrets are user-operated

Never run `sops`, never edit `.sops.yaml`, never generate age keys, never run `just rekey`, and never edit ciphertext under `../nix-secrets/secrets/`.

Write the Nix that references `sops.secrets."<path>"`, state the exact YAML key path and file, then stop. A secret that does not exist yet also gets an assertion naming the missing key: `lib.hasInfix "<key>:" (builtins.readFile sopsFile)` (pattern: `modules/hosts/darwin/omni/default.nix`).

`../nix-secrets` is a locked remote input: local edits are invisible until the user pushes there and runs `just update-nix-secrets` here. Say so explicitly.

## Before claiming anything works

- **New files need `git add --intent-to-add .`** Untracked files are invisible to the flake; evaluation succeeds while the change does nothing. `just rebuild`/`build`/`deploy` run it in `rebuild-pre`.
- **Evaluate:**
  - darwin: `nix eval .#darwinConfigurations.<host>.config.system.build.toplevel.drvPath`
  - NixOS: `nix eval .#nixosConfigurations.<host>.config.system.build.toplevel.drvPath`
  - standalone: `nix eval .#homeConfigurations.\"jhl@<host>\".activationPackage.drvPath`
- **Read generated artifacts:** `nix build .#darwinConfigurations.<host>.config.home-manager.users.jhl.xdg.configFile."<path>".source`, then `cat` it (standalone: `.#homeConfigurations."jhl@<host>".config.xdg.configFile."<path>".source`).
- **Gate:** `just check` builds every machine native to the current system. There is no CI.
- **Format:** `just fmt`, or `nix run nixpkgs#alejandra -- --check <files>`.

## Silent failure modes

- `hosts/common/optional/**` is not auto-imported; a file there does nothing until a host names it. `modules/**` is auto-imported.
- `lib.custom.relativeToRoot` takes a string, not a path literal.
- `sops.templates.<x>.path` and `sops.secrets.<x>.path` are symlinks into `/run/secrets`; writes through them are wiped next activation, and `/run` is volatile.
- Homebrew runs `onActivation.cleanup = "zap"`: removing a brew from Nix uninstalls it; a manual `brew install` is temporary.
- `home.file` / `xdg.configFile` are read-only store symlinks. Do not manage a file its own tool writes back (Claude Code `settings.json`, omp `config.yml` and `mcp.json`, Zed UI settings).
- `programs.zed-editor` uses `mutableUserSettings = true`, a one-way merge: removing a key from Nix leaves it in `settings.json`.
- `hosts/home/<Host>/default.nix` is not a module; it is `evalModules`'d against `modules/common/host-spec.nix` alone and may set only `hostSpec`. Keep `hosts/common/core/host-spec.nix` free of `imports` and other options for the same reason.
- `home/jhl/common/core/*.nix` reaches Linux. Darwin-only paths (`/opt/homebrew`, `/etc/profiles/per-user`, `launchd`, `targets.darwin`) go in `common/core/darwin.nix` or `common/core/darwin/`.
- Skills under `skills/<name>/` deploy to `~/.agents/skills/<name>` via `home/jhl/common/core/skills.nix`; a new skill needs intent-to-add and a rebuild.
