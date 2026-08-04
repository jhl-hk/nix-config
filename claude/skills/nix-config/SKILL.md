---
name: nix-config
description: Operates jhl's nix-darwin monorepo at /Users/jhl/Documents/nix-config. Use when adding or editing a Darwin host, a system module, a home-manager program or dotfile, a shell config, a Homebrew brew/cask/masApp, or a per-host optional module; when touching files under hosts/, home/, claude/, assets/, flake.nix, or justfile; when running just (switch, build, check, check-beta, update, clean), darwin-rebuild, or nix flake check; when debugging import lists that did not take effect, system.stateVersion type errors (int on Darwin, string for home), hostname/flake-attribute mismatches, Homebrew zap cleanup removing apps, or masApps failing on a macOS seed build; whenever a .nix file in this repo is the target, even when the user just says "add module", "add app", or "rebuild".
---

# nix-config

Operating manual for `/Users/jhl/Documents/nix-config` — a **Darwin-only** nix-darwin + home-manager flake managing three Macs for the single user `jhl`. `nixosConfigurations` exists but is empty and commented out.

This repo is deliberately small and explicit. There is **no** `lib/`, `modules/`, `pkgs/`, `overlays/`, `lib.custom`, `scanPaths`, `relativeToRoot`, sops, or secrets tree. Do not invent them. Every wiring step is a literal path in an `imports` list.

## Core mental model

One composition lane, assembled by the `mkDarwin` helper in `flake.nix`:

```
mkDarwin { hostname, system ? "aarch64-darwin", username, modules ? [] }
  ├─ ./hosts/common/core        # cross-platform baseline (nix settings, base pkgs)
  ├─ ./hosts/common/darwin      # everything macOS-wide
  ├─ ./hosts/darwin/${hostname} # this machine only
  └─ home-manager.darwinModules.home-manager
       └─ users.jhl = import ./home
```

`specialArgs` passes `inputs outputs hostname username` to system modules; `extraSpecialArgs` passes the same four to home-manager modules. So any file in the tree can take `{ username, hostname, ... }` directly.

**Nothing is auto-imported.** Creating a `.nix` file does nothing until you add it to a parent `default.nix` `imports` list. The four aggregation points:

| New file | Add its path to |
|---|---|
| `hosts/common/darwin/<name>.nix` | `hosts/common/darwin/default.nix` |
| `hosts/common/core/<name>.nix` | `hosts/common/core/default.nix` |
| `home/programs/<name>.nix` | `home/programs/default.nix` |
| `home/shell/<name>.nix` | `home/shell/default.nix` |

`hosts/optional/<name>.nix` is the exception — it has no aggregator. Each host opts in individually with `../../optional/<name>.nix` in its own `imports`.

**Two nixpkgs channels.** `nixpkgs` is unstable (drives home-manager and `pkgs`); `nixpkgs-darwin` is `nixpkgs-26.05-darwin` and is what `darwin` follows. Because they are mixed, `home.enableNixpkgsReleaseCheck = false` in `home/default.nix`. Leave it false.

**Homebrew is the application layer.** Nix manages CLI baseline and dotfiles; GUI apps and most language toolchains come from `hosts/common/darwin/apps.nix`. `onActivation.cleanup = "zap"` means **any Homebrew package not declared there is uninstalled on the next switch**. Adding an app by hand with `brew install` is temporary — declare it or lose it.

**Nix tracks only git-tracked files.** A brand-new `.nix` file (or skill file) is invisible to `nix eval` / `just build` until it is `git add`-ed — the failure reads `Path '…' in the repository … is not tracked by Git`. Stage new files before building.

## Quick recipes

Pick the first match.

### Recipe 1 — a setting that should apply to every Mac

Add to the relevant existing file in `hosts/common/darwin/`: `system-defaults.nix` for `system.defaults.*` (macOS preference domains) and `networking.*`, `apps.nix` for Homebrew, `default.nix` for user/shell/PAM/system packages. Only create a new file if the topic is genuinely new:

```nix
{ pkgs, ... }:

#############################################################
#
#  <Title>
#  <One-line purpose>
#
#############################################################

{
  # ...
}
```

Then add `./<name>.nix` to the `imports` list in `hosts/common/darwin/default.nix`.

### Recipe 2 — a feature only some Macs should get

Create `hosts/optional/<name>.nix` as a plain config-only module (see `hosts/optional/steam.nix`, which just appends a Homebrew cask). Then in each host that wants it:

```nix
# hosts/darwin/<HostName>/default.nix
imports = [
  ../../optional/<name>.nix
];
```

The relative path is `../../optional/…` because host files sit two levels down at `hosts/darwin/<HostName>/`. This is the audit point — reading a host file tells you what that machine adds beyond the common baseline.

### Recipe 3 — a one-off for a single machine

Put it directly in `hosts/darwin/<HostName>/default.nix`. Reserve this for things that are inherently machine-bound: `local.macosBeta`, wallpaper activation scripts, host-specific packages. Anything reusable belongs in Recipe 2.

### Recipe 4 — a home-manager program or dotfile

Create `home/programs/<name>.nix`, then add `./<name>.nix` to `home/programs/default.nix`. Shape:

```nix
{ config, pkgs, ... }:

#############################################################
#
#  <Program> Configuration
#
#############################################################

{
  programs.<name> = {
    enable = true;
    # ...
  };
}
```

For a program whose binary comes from a Homebrew cask or brew rather than nixpkgs, set `package = null` and let home-manager manage only the config files — see `home/programs/zed.nix` (Zed is a cask; it also relies on the default `mutableUserSettings = true` so Zed's own writes to `settings.json` survive activation) and `home/programs/tmux.nix` (tmux is a brew; home-manager writes only `~/.config/tmux/tmux.conf`).

`package = null` only works where the module declares the option with `mkPackageOption … { nullable = true; }`. Check the module source before assuming it; a non-nullable `package` fails with a type error.

Shell-related config (`zsh`, `starship`) goes in `home/shell/` with the same pattern against `home/shell/default.nix`.

### Recipe 5 — install an application

Edit `hosts/common/darwin/apps.nix`:

- CLI tool → `brews`
- GUI app or font → `casks`
- Mac App Store → `masApps` as `"Name" = <numeric id>;` (requires `mas signin`)
- Third-party tap → `taps`, and it **must** carry `trusted = true`. Homebrew 6.0 enabled `HOMEBREW_REQUIRE_TAP_TRUST`, so an untrusted tap fails during activation before its formulae are fetched.

Prefer nixpkgs (`environment.systemPackages` in `hosts/common/core/default.nix`, or `home.packages`) for anything that works well there; use Homebrew for GUI apps, casks with macOS integration, and toolchains that are painful under Nix on Darwin.

### Recipe 6 — add a new Mac

Two edits, both required:

1. `flake.nix` — add an attribute to `darwinConfigurations`. **The attribute name must exactly equal what `hostname` prints on that machine**, because `just switch` builds `.#{{hostname}}`:

```nix
<HostName> = mkDarwin {
  hostname = "<HostName>";
  system = "aarch64-darwin";   # or "x86_64-darwin" on Intel
  username = "jhl";
};
```

2. `hosts/darwin/<HostName>/default.nix` — set all three identity fields:

```nix
{ pkgs, ... }:

{
  networking.hostName = "<HostName>";
  networking.computerName = "<HostName>";
  system.defaults.smb.NetBIOSName = "<HostName>";
}
```

Then run `just switch` on that Mac. Add `local.macosBeta = true;` if it is on a seed build (`just check-beta` reports).

### Recipe 7 — cross-platform / future NixOS

`hosts/common/core/` is the only tree imported by both platforms. Put genuinely OS-agnostic settings there (nix daemon settings, GC, `allowUnfree`, base packages). Anything referencing `homebrew`, `system.defaults`, or `security.pam` is Darwin-only and belongs under `hosts/common/darwin/`.

### Recipe 8 — add or edit a Claude Code skill

Skill sources live in this repo at `claude/skills/<name>/SKILL.md` and are deployed by `home/programs/claude.nix`, which symlinks each one to `~/.claude/skills/<name>` (user scope — available in every project, not just this repo).

To add a skill:

1. Write `claude/skills/<name>/SKILL.md` with YAML frontmatter (`name`, `description`). The `description` is the *only* thing Claude sees when deciding whether to load the skill, so it must enumerate concrete triggers — file paths, command names, error messages.
2. Add `<name>` to the `skills` list in `home/programs/claude.nix`.
3. `git add` the new files, then `just switch`.

The directory is `claude/`, **not** `.claude/`. A `.claude/skills/` at the repo root would register the same skill a second time at project scope, so the same name would resolve twice. Only `skills` is nix-managed; `~/.claude/settings.json`, `CLAUDE.md`, and memory stay mutable and owned by Claude Code, because `home.file` produces read-only store symlinks that the app cannot write back to.

## Critical conventions

- **`system.stateVersion = 6` is an integer on Darwin.** Home-manager's `home.stateVersion = "26.05"` is a string. They are different options with different types; swapping them is an eval error. Neither tracks the running OS version — they pin migration behavior from the original install. Do not bump either without reading the corresponding release notes.
- **`local.macosBeta` is a declared option, not a detection.** Defined in `hosts/common/darwin/options.nix`, consumed in `apps.nix` as `masApps = lib.optionalAttrs (!config.local.macosBeta) { … }`. Nix evaluates purely and cannot see the OS build, so a seed-build Mac must set it by hand — `mas` cannot install on seed builds and activation fails otherwise. `SeandeMac-Studio` currently sets it.
- **The shell `hostname` must match the flake attribute.** The justfile captures `hostname` into a variable and builds `.#{{ hostname }}`. If they diverge, `just switch` fails with a missing-attribute error rather than anything descriptive.
- **`cleanup = "zap"` is destructive by design.** Undeclared Homebrew packages are removed on activation. When a user reports "my app disappeared", check `apps.nix` first.
- **Match the banner comment style.** Nearly every file opens with the `####…` block shown above. Comments are freely bilingual (Chinese/English) — mirror whatever the surrounding file uses.
- **The formatter is declared as `alejandra`** in `flake.nix`, but the existing tree is not alejandra-formatted (it uses `{ x, y, ... }:` spacing that alejandra rewrites). Do not run `nix fmt` across the repo as a drive-by — it produces a huge unrelated diff. Match the local file's existing style instead.
- **`username` is a `specialArgs` parameter, but home-manager's user is hardcoded** as `users.jhl = import ./home` in `flake.nix`, and `home/default.nix` hardcodes `username`/`homeDirectory` again. Adding a second user means changing all three places; the `username` argument alone is not enough.
- **Do not add secrets to this repo.** There is no sops/age setup. The SSH allowed-signers public key in `home/default.nix` is public key material and fine; private material is not managed here.

## macOS settings Nix cannot manage

Some macOS state is outside nix-darwin's reach. When a request lands here, say so rather than writing a `system.defaults` key that will silently do nothing:

- **Privacy & Security permissions (TCC)** — Local Network, Full Disk Access, Screen Recording, Accessibility, Camera/Mic. These live in SIP-protected databases with no writable `defaults` domain. `tccutil` cannot even reset `LocalNetwork` on macOS 27. They are per-machine manual steps, or MDM-profile territory. A denied Local Network grant surfaces as `EHOSTUNREACH` / "No route to host" to a LAN address, *not* as a permission error.
- **Keychain entries** — e.g. API keys for Zed's `openai_compatible` providers. `settings.json` declares the provider; the credential is entered in the app UI and stored in the Keychain.
- **Login items requiring user approval**, and anything gated behind a one-time system dialog.

## Commands

```
just switch      # runs `check` first, then: sudo darwin-rebuild switch --flake .#$(hostname)
just build       # build without activating
just check       # nix flake check --all-systems
just check-beta  # report whether this Mac is on a seed catalog -> whether to set local.macosBeta
just update      # nix flake update && brew update && brew upgrade
just clean       # sudo nix-collect-garbage -d && mo clean
```

`just switch` depends on `check`, so a flake error blocks activation before anything is applied. There is no deploy/remote path — every Mac is rebuilt locally on itself.

## Repository map

```
flake.nix                        mkDarwin helper, 3 darwinConfigurations, alejandra formatter
justfile                         switch build check check-beta update clean
hosts/
  common/
    core/default.nix             base packages; imports nix-settings.nix
    core/nix-settings.nix        flakes, allowUnfree, gc (mkDefault)
    darwin/default.nix           stateVersion 6, user, zsh, TouchID sudo, systemPath;
                                 imports options.nix system-defaults.nix apps.nix
    darwin/options.nix           declares local.macosBeta
    darwin/system-defaults.nix   system.defaults.* + networking.*  (126 lines)
    darwin/apps.nix              homebrew: taps brews casks masApps
  darwin/
    jhlsMacBookPro/default.nix   imports optional/steam.nix
    jhlsMacBookAir/default.nix   imports optional/steam.nix; wallpaper activation script
    SeandeMac-Studio/default.nix local.macosBeta = true
  optional/steam.nix             opt-in; no aggregator, hosts import it directly
home/
  default.nix                    username/homeDirectory/stateVersion; imports ./programs ./shell
  programs/default.nix           claude git ssh keyboard stats tmux typora zed
  programs/claude.nix            symlinks ../../claude/skills/* into ~/.claude/skills/
  shell/default.nix              zsh starship
claude/skills/<name>/SKILL.md    Claude Code skill sources, deployed by home/programs/claude.nix
assets/                          wallpapers referenced by activation scripts
```
