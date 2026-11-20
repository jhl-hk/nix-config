# Recipes — Adding Modules, Services, Packages, Hosts

Mistakes that apply to every recipe: CLAUDE.md and SKILL.md § Common Mistakes.

## Contents

- [Decision tree](#decision-tree)
- [Recipe 1: drop-in optional system feature](#recipe-1-drop-in-optional-system-feature)
- [Recipe 2: reusable module with options](#recipe-2-reusable-module-with-options)
- [Recipe 3: add a custom package](#recipe-3-add-a-custom-package)
- [Recipe 4: override a nixpkgs package](#recipe-4-override-a-nixpkgs-package)
- [Recipe 5: add a home-manager program or dotfile](#recipe-5-add-a-home-manager-program-or-dotfile)
- [Recipe 6: add a Homebrew package](#recipe-6-add-a-homebrew-package)
- [Recipe 7: add a Mac](#recipe-7-add-a-mac)
- [Recipe 7b: add a non-NixOS Linux host](#recipe-7b-add-a-non-nixos-linux-host)
- [Recipe 7c: add a NixOS host](#recipe-7c-add-a-nixos-host)
- [Recipe 8: system-scope secret](#recipe-8-system-scope-secret)
- [Recipe 8b: home-manager secret (standalone lane)](#recipe-8b-home-manager-secret-standalone-lane)
- [Recipe 9: add a user](#recipe-9-add-a-user)
- [Recipe 10: add an MCP server](#recipe-10-add-an-mcp-server)
- [Recipe 11: add a skill](#recipe-11-add-a-skill)

## Decision tree

Match the intent to exactly one row before touching files.

| Intent | Location | Recipe |
|---|---|---|
| System package on every system-lane machine (Macs + NixOS) | `environment.systemPackages` in `hosts/common/core/default.nix` | — |
| System package on every Mac | `environment.systemPackages` in `hosts/common/core/darwin.nix` | — |
| System package on every NixOS host | `hosts/common/core/nixos.nix` (baseline) or `hosts/common/optional/nixos/dev.nix` (dev toolset) | — |
| System package for one host | `environment.systemPackages` in `hosts/<lane>/<Host>/default.nix` (not on `hosts/home/`) | — |
| System feature, no knobs, hosts opt in by importing | `hosts/common/optional/{darwin,nixos,common}/<name>.nix` | 1 |
| System feature with `enable` + options | `modules/hosts/{common,darwin,nixos}/<name>/default.nix` (auto-discovered) | 2 |
| Package not in nixpkgs | `pkgs/common/<name>/package.nix` (auto-discovered) | 3 |
| Tweak to an existing nixpkgs package | `overlays/default.nix` | 4 |
| User dotfile / program, cross-platform | `home/jhl/common/core/<name>.nix` + add to that dir's `default.nix` | 5a |
| User dotfile, macOS-only | `home/jhl/common/core/darwin/<name>.nix` + add to `common/core/darwin.nix` | 5b |
| User dotfile, Linux-only (NixOS + standalone) | `home/jhl/common/core/linux.nix` | 5b |
| Opt-in user feature | `home/jhl/common/optional/<cat>/<name>.nix`, imported by `home/jhl/<Host>.nix` | 5c |
| Per-host home tweak, no new file | `home/jhl/<Host>.nix` directly | 5d |
| Home-manager option module | `modules/home/<name>.nix` (auto-discovered) | 2 |
| Homebrew brew/cask/masApp, every Mac | `hosts/common/core/darwin/apps.nix` | 6 |
| Homebrew GUI casks / heavy CLI, desktop Macs | `hosts/common/optional/darwin/{desktop,dev-extras}.nix` | 6 |
| Homebrew brew/cask, one machine | `hosts/common/optional/darwin/<name>.nix` | 6 |
| New Mac | `hosts/darwin/<Host>/default.nix` + `home/jhl/<Host>.nix` | 7 |
| New non-NixOS Linux box | `hosts/home/<Host>/default.nix` + `home/jhl/<Host>.nix` | 7b |
| New NixOS machine | `hosts/nixos/<Host>/{default,hardware-configuration}.nix` + `home/jhl/<Host>.nix` | 7c |
| Secret on a Mac or NixOS host | `sops.secrets` in the consuming system module | 8 |
| Secret on a standalone Linux host | `home/jhl/common/optional/sops/standalone.nix` | 8b |
| Second user | `hosts/common/users/<new>/` + `home/<new>/` | 9 |
| MCP server for omp | `modules/home/mcp-servers.nix` or `omp.mcpServers` | 10 |
| Agent skill | `skills/<name>/SKILL.md` | 11 |

Optional file vs `modules/` module: an optional file is plain config a machine either wants or doesn't. Use a module once two machines need the feature with different inputs.

`modules/hosts/nixos/` means NixOS, not Linux: standalone hosts never import it, so something for every Linux machine goes in `home/jhl/common/core/linux.nix`. `modules/common/` holds only `host-spec.nix`, the schema evaluated by every system scope and by `evalHostSpec`; home-manager does not import it. A system option module may be `modules/hosts/<platform>/<name>/default.nix` or a single `<name>.nix`; `scanPaths` picks up either. Modules define options; enabling stays per host or per user.

## Recipe 1: drop-in optional system feature

Pattern source: `hosts/common/optional/darwin/steam.nix`.

Directory by reach: `optional/darwin/` (Macs), `optional/nixos/` (NixOS), `optional/common/` (both; e.g. `common/llm.nix`). Plain module, no `options` block:

```nix
{ ... }:
{
  darwinHomebrew.casks = [ "steam" ];
}
```

Enable it in the host's imports:

```nix
# hosts/darwin/jhlsMacBookPro/default.nix
{ lib, ... }:
{
  imports = map lib.custom.relativeToRoot [
    "hosts/common/optional/darwin/steam.nix"
  ];

  hostSpec.hostName = "jhlsMacBookPro";
}
```

## Recipe 2: reusable module with options

Pattern sources: `modules/hosts/darwin/yubikey/default.nix`, `modules/hosts/darwin/omni/default.nix`.

Place at `modules/hosts/<platform>/<name>/default.nix` (system) or `modules/home/<name>.nix` (home-manager). Each `modules/**/default.nix` calls `lib.custom.scanPaths ./.`, so the file is imported with no registration.

```nix
{ config, lib, ... }:
let
  cfg = config.<name>;
  inherit (lib) mkOption types;
in
{
  options.<name> = {
    enable = lib.mkEnableOption "<name>";   # defaults to false
    someList = mkOption { type = types.listOf types.str; default = [ ]; description = "..."; };
  };

  config = lib.mkIf cfg.enable {
    # ...
  };
}
```

A host turns it on by setting the option, with no import:

```nix
# hosts/darwin/jhlsMacBookPro/default.nix
darwinYubikey.enable = true;
```

`mkEnableOption` is the default. Use `mkOption { type = types.bool; default = true; }` only for a feature every host gets unless it opts out — `darwinHomebrew.enable` (`modules/hosts/darwin/homebrew/default.nix`) is the one case.

Use `listOf` when several modules contribute: definitions concatenate, which is how `hosts/common/core/darwin/apps.nix` and `hosts/common/optional/darwin/steam.nix` both feed `darwinHomebrew.casks`. `attrsOf` merges by key (`masApps`).

`nullOr path` option plus an activation script: `modules/hosts/darwin/wallpaper/default.nix`.

## Recipe 3: add a custom package

Create `pkgs/common/<name>/package.nix`:

```nix
{ lib, stdenv, fetchFromGitHub }:
stdenv.mkDerivation {
  pname = "<name>";
  version = "...";
  src = fetchFromGitHub { owner = "..."; repo = "..."; rev = "..."; hash = "sha256-..."; };
  installPhase = ''
    install -m755 -D <file> $out/bin/<name>
  '';
  meta.license = lib.licenses.mit;
}
```

Arguments come from `callPackage`. Rust: `rustPlatform.buildRustPackage { ... cargoHash = ...; }`.

No other step. Both the `additions` overlay and the `packages` output run `packagesFromDirectoryRecursive` over `pkgs/common`. Use as `pkgs.<name>`; build with `nix build .#packages.aarch64-darwin.<name>`.

## Recipe 4: override a nixpkgs package

Edit `overlays/default.nix`. Five layers; use one of these two:

```nix
modifications = _final: prev: {
  foo = prev.foo.overrideAttrs (old: { patches = old.patches ++ [ ./fix.patch ]; });
};

linuxModifications = _final: prev: prev.lib.optionalAttrs prev.stdenv.isLinux {
  bar = _final.unstable.bar;
};
```

`lib.optionalAttrs` makes the attribute absent on macOS, so it never hits "unknown attribute".

Newer version only: use `pkgs.unstable.<x>` (the `unstable-packages` layer, `allowUnfree`). No override.

Do not edit the `customLib` layer; see `architecture.md` § The two lib plumbing paths.

## Recipe 5: add a home-manager program or dotfile

### 5a. Cross-platform, always on

Create `home/jhl/common/core/<name>.nix` and add `./<name>.nix` to the hand-written imports in `home/jhl/common/core/default.nix`.

```nix
{ config, hostSpec, ... }:
{
  programs.git = {
    enable = true;
    settings.user = {
      name  = hostSpec.userFullName;
      email = hostSpec.email.user;
      signingKey = "~/.ssh/${config.sshKeys.primary}.pub";
    };
  };
}
```

### 5b. One platform, always on

- macOS: `home/jhl/common/core/darwin/<name>.nix`, added to `home/jhl/common/core/darwin.nix` imports. Anything with `/opt/homebrew`, `/etc/profiles/per-user`, `launchd.agents`, `targets.darwin.*` or `osascript` goes here.
- Linux: `home/jhl/common/core/linux.nix`. It loads on NixOS and standalone hosts alike; NixOS-only things go in `hosts/common/core/nixos.nix`.

### 5c. Opt-in per host

Create `home/jhl/common/optional/<cat>/<name>.nix` and name it in the host's home file:

```nix
# home/jhl/jhlsMacBookPro.nix
imports = [
  ./common/core
  ./common/optional/editors/zed.nix
];
```

Categories in use: `ai`, `desktop`, `editors`, `k8s`, `nix`, `shell`, `sops`.

### 5d. Per-host tweak, no new file

```nix
# home/jhl/<Host>.nix
sshKeys.primary = "id_ykmini";
```

## Recipe 6: add a Homebrew package

| Reach | File |
|---|---|
| Every Mac (CLI baseline + `ghostty`, `tailscale-app` casks) | `hosts/common/core/darwin/apps.nix` |
| GUI casks, Mac App Store titles | `hosts/common/optional/darwin/desktop.nix` (jhlsMacBookPro, SeandeMac-Studio) |
| Heavier CLI | `hosts/common/optional/darwin/dev-extras.nix` (jhlsMacBookPro, SeandeMac-Studio) |
| One machine | new `hosts/common/optional/darwin/<name>.nix` (Recipe 1) |

```nix
darwinHomebrew = {
  brews = [ ... "newthing" ];
  casks = [ ... "new-app" ];
  taps  = [ { name = "owner/tap"; trusted = true; } ];
  masApps = { "App Name" = 1234567890; };
};
```

- **`trusted = true` on non-official taps.** Homebrew 6.0 enables `HOMEBREW_REQUIRE_TAP_TRUST`. `trusted` emits `trusted: true` into the Brewfile, which `brew bundle` applies before fetching; no manual `brew trust`.
- **`masApps` bypasses `brew bundle`.** `modules/hosts/darwin/homebrew/mas.nix` installs them from `postActivation` after matching `sw_vers -buildVersion` against the seed shape (`26A5388g` yes, `26A428` no); seed builds skip them. Install-only: removing a line leaves the app installed. A failed App Store install cannot abort the Brewfile. Seed-programme enrollment (`CatalogURL`) is not the signal; `jhlsMacBookPro` is enrolled on release software. `just check-beta` shows the current decision.
- **`onActivation.cleanup = "zap"`.** Anything undeclared is uninstalled on the next switch.

## Recipe 7: add a Mac

Two files, no `flake.nix` edit.

```nix
# hosts/darwin/<Name>/default.nix
{ lib, ... }:
{
  imports = map lib.custom.relativeToRoot [
    # "hosts/common/optional/darwin/desktop.nix"
  ];

  hostSpec = {
    hostName = "<Name>";
    isMobile = false;
  };
}
```

```nix
# home/jhl/<Name>.nix
{ ... }:
{
  imports = [
    ./common/core
    ./common/optional/editors/zed.nix
  ];
}
```

`hostName` must equal the directory name: `hosts/common/users/jhl/darwin.nix` imports `home/jhl/${hostName}.nix`, and `flake.nix` keys the output on the directory name.

The Mac's age public key must be a recipient in `../nix-secrets/.sops.yaml` before any secret decrypts there (user-operated; see `nix-secrets.md`). Then run `just rebuild` on that Mac.

## Recipe 7b: add a non-NixOS Linux host

Nix on a distro that owns the system. Output `homeConfigurations."<user>@<Name>"`, no system configuration. Pattern source: `hosts/home/jhlsRogZephyrus/`, `home/jhl/jhlsRogZephyrus.nix`.

```nix
# hosts/home/<Name>/default.nix
{ ... }:
{
  hostSpec = {
    hostName = "<Name>";
  };
}
```

```nix
# home/jhl/<Name>.nix
{ ... }:
{
  imports = [
    ./common/core
    ./common/optional/ai/omp.nix
    ./common/optional/editors/zed.nix

    # The distro's nix owns /etc/nix/nix.conf; flakes go through ~/.config/nix/nix.conf.
    ./common/optional/nix/standalone.nix

    # Home-manager sops; repoints llm, cloudflare, wakatime key files (Recipe 8b).
    ./common/optional/sops/standalone.nix
  ];
}
```

Desktop hosts also import `./common/optional/desktop/{niri,DankMaterialShell,fcitx5}.nix`.

Differences from Recipe 7:

- **The host file is not a module.** `flake.nix` passes it to `lib.custom.evalHostSpec`, an `evalModules` over `modules/common/host-spec.nix` alone. Only `hostSpec` exists; `imports`, `environment.*`, `networking.*` fail as unknown options.
- **No `hosts/common/core`, no `hosts/common/optional/**`.** No system packages, `users.users` or `nix.gc`. Root-level work belongs to the distro's package manager.
- **Secrets need `sops/standalone.nix`** plus the host's age key in `.sops.yaml`, and `~/.config/sops/age/keys.txt` on the machine.
- **Platform sibling is `linux.nix`.**

Run `just rebuild` on that machine. `scripts/rebuild.sh` resolves `hosts/home/$(uname -n)`; see `commands.md`.

## Recipe 7c: add a NixOS host

Pattern source: `hosts/nixos/DevEnv/`, `home/jhl/DevEnv.nix`. Output `nixosConfigurations.<Name>`, built by `mkNixosHost` with `home-manager-unstable.nixosModules.home-manager`, `x86_64-linux`.

```nix
# hosts/nixos/<Name>/default.nix
{ config, lib, ... }:
{
  imports =
    [ ./hardware-configuration.nix ]
    ++ map lib.custom.relativeToRoot [
      "hosts/common/optional/nixos/dev.nix"
      # "hosts/common/optional/nixos/forgejo.nix"
      # "hosts/common/optional/common/llm.nix"
    ];

  hostSpec = {
    hostName = "<Name>";
    isServer = true;
    useWindowManager = false;
  };

  boot.loader.grub = { enable = true; device = "/dev/sda"; };   # match the machine

  services.openssh = {
    enable = true;
    settings = { PermitRootLogin = "no"; PasswordAuthentication = false; };
  };

  users.users.${config.hostSpec.username}.openssh.authorizedKeys.keys = [ "..." ];
}
```

```nix
# home/jhl/<Name>.nix
{ ... }:
{
  imports = [ ./common/core ];
}
```

- `hardware-configuration.nix` comes from `nixos-generate-config` on the target.
- `hosts/common/core/nixos.nix` supplies `networking.hostName`, `programs.zsh.enable`, Ghostty terminfo and `system.stateVersion = "26.05"`.
- `hosts/common/users/jhl/nixos.nix` wires home-manager to `home/jhl/${hostName}.nix`.
- System sops works as on a Mac (Recipe 8); the host needs its own age key in `.sops.yaml` and `~/.config/sops/age/keys.txt`.

Activate:

| Where | Command |
|---|---|
| From another machine | `just deploy <Name> [TARGET]` — `TARGET` defaults to the ssh alias `<Name>` |
| On the host | `just rebuild` (`rebuild.sh` detects `/etc/NIXOS`) |

## Recipe 8: system-scope secret

Macs and NixOS. Declare `sops.secrets."<area>/<name>"` in the consuming module (`hosts/common/core/sops.nix` imports sops-nix and sets `sops.age.keyFile`; it declares no secrets), use `sops.templates` when the secret is one substring of a larger file, and add an evaluation-time `lib.hasInfix` guard naming the key. Code, the symlink and volatility gotchas, failure visibility and the hand-off (YAML key path and file, then stop): `nix-secrets.md` § Consuming secrets: system scope, § Failure visibility and § What agents must not do.

Worked examples:

- `hosts/common/core/darwin/forgejo.nix`: `tea/token`, `pathExists` plus nested-key guard, an assertion message that shows the `just sops-edit shared` YAML.
- `hosts/common/core/darwin/ssh-shared-key.nix`: `ssh/id_shared` with `path` set to `~/.ssh/id_shared`.
- `hosts/common/optional/common/llm.nix`: two keys, each guarded by its parent section.

No imported module uses `sops.templates`. `hosts/common/optional/darwin/npmrc.nix` is the template example (`~/.npmrc` with the token placeholder, guarded like `forgejo.nix`). Its key `npm/jianyuelab_token` does not exist yet and no host imports it; importing it fails evaluation until the key is added.

## Recipe 8b: home-manager secret (standalone lane)

Pattern source: `home/jhl/common/optional/sops/standalone.nix`, the only home-manager sops file. Add the secret there:

```nix
sops.secrets = {
  "<area>/<name>" = {};                       # defaultSopsFile = shared.yaml
  "ssh/id_shared" = {
    mode = "0400";
    path = "${config.home.homeDirectory}/.ssh/id_shared";
  };
};

# Consumers default to /run/secrets/...; repoint them.
<consumer>.keyFile = lib.mkForce (config.sops.secrets."<area>/<name>".path);
```

- Decryption target, links and the `sops-nix.service` user service: `nix-secrets.md` § Consuming secrets: home-manager scope.
- Every consumer option with a `/run/secrets` default needs a `mkForce` repoint here (`llm.apiKeyFile`, `llm.providers.JianyueLab.apiKeyFile`, `cloudflare.apiTokenFile`, `wakatime.apiKeyFile` today).
- systemd user services that read a secret order after `sops-nix.service`; example: `forgejo-login` in the same file.
- Never import it on a Mac or NixOS host; the system lane already provides the secrets.

## Recipe 9: add a user

No dedicated tooling; mirror `jhl`.

1. Copy `hosts/common/users/jhl/` to `hosts/common/users/<new>/` with the same `default.nix` / `darwin.nix` / `nixos.nix` split. `hosts/common/core/default.nix` must import both `"hosts/common/users/<new>"` and `"hosts/common/users/<new>/${platform}.nix"`.
2. Gate Linux-only attrs: `lib.optionalAttrs pkgs.stdenv.isLinux { group = "wheel"; }`.
3. Copy `home/jhl/` to `home/<new>/`, keeping `common/core/{default,darwin,linux}.nix` and the needed `common/optional/` subtrees.
4. `hostSpec.username` is one value set in `hosts/common/core/host-spec.nix`. Multi-user needs that generalised; flag it to the user.

## Recipe 10: add an MCP server

| Server kind | Where |
|---|---|
| Remote streamable-HTTP, OAuth, on every host with omp | `modules/home/mcp-servers.nix` → `mcpServers.<name>.url` default |
| stdio, extra fields, or one host only | `omp.mcpServers.<name>` in a home module, imported next to `optional/ai/omp.nix` |

```nix
# modules/home/mcp-servers.nix  (default attrset)
<name>.url = "https://example.net/mcp";
```

```nix
# home/jhl/common/optional/ai/<name>-mcp.nix
{ pkgs, ... }:
{
  omp.mcpServers.<name> = {
    type = "stdio";
    command = "${pkgs.uv}/bin/uvx";
    args = [ "..." ];
  };
}
```

- `optional/ai/omp.nix` maps every `mcpServers` entry to `{ type = "http"; url; }` in `omp.mcpServers` and merges the result into `~/.omp/agent/mcp.json` by name on activation. Entries added in omp (`/mcp add`) survive.
- Nothing secret goes in either option; HTTP servers authenticate by OAuth inside omp.
- Example: `home/jhl/common/optional/ai/blender-mcp.nix` (needs `hosts/common/optional/darwin/blender.nix` on the system side).

## Recipe 11: add a skill

1. Create `skills/<name>/SKILL.md`; follow `skills/README.md`. **REQUIRED SUB-SKILL:** Use writing-skills.
2. No wiring: `home/jhl/common/core/skills.nix` scans `skills/` for directories with a `SKILL.md` and links each to `~/.agents/skills/<name>`.
3. Third-party skill: keep the upstream `LICENSE` and add `UPSTREAM.md` (source URL and path, commit, license, `Local changes`) per `skills/README.md` § E.
4. `git add --intent-to-add .`, then rebuild.

Other skill sources in `skills.nix`:

| Source | Mechanism |
|---|---|
| `jianyuelab-docs` input (`<repo>/skills`) | scanned; edits need push + `nix flake update jianyuelab-docs` |
| `~/Documents/Dev/JianyueLab/skills` | live symlinks made by `home.activation.liveSkills`; new directories need a switch |
