# Recipes — Adding Modules, Services, Packages, Hosts

The central reference for extending nix-config. Each recipe maps an intent ("add X") to a directory, a file template, and the wiring step. Excerpts come from the live repo.

## Contents

- [Decision tree](#decision-tree)
- [Recipe 1: drop-in optional system feature](#recipe-1-drop-in-optional-system-feature)
- [Recipe 2: reusable module with options](#recipe-2-reusable-module-with-options)
- [Recipe 3: add a custom package](#recipe-3-add-a-custom-package)
- [Recipe 4: override a nixpkgs package](#recipe-4-override-a-nixpkgs-package)
- [Recipe 5: add a home-manager program or dotfile](#recipe-5-add-a-home-manager-program-or-dotfile)
- [Recipe 6: add a Homebrew package](#recipe-6-add-a-homebrew-package)
- [Recipe 7: add a host](#recipe-7-add-a-host)
- [Recipe 8: wire something that needs a secret](#recipe-8-wire-something-that-needs-a-secret)
- [Recipe 9: add a user](#recipe-9-add-a-user)
- [Common pitfalls](#common-pitfalls)

## Decision tree

Match the intent to exactly one row before touching files.

| Intent | Location |
|---|---|
| System package every Mac should have | `environment.systemPackages` in `hosts/common/core/default.nix` |
| System package for one Mac | `environment.systemPackages` in `hosts/darwin/<Host>/default.nix` |
| Reusable system feature, no knobs, hosts opt in by importing | `hosts/common/optional/darwin/<name>.nix` |
| Reusable system feature with `enable` + options | `modules/hosts/{common,darwin,nixos}/<name>/default.nix` (auto-discovered) |
| Homebrew brew/cask/masApp, fleet-wide | `hosts/common/core/darwin/apps.nix` |
| Homebrew brew/cask, one machine | `hosts/common/optional/darwin/<name>.nix` |
| Package not in nixpkgs | `pkgs/common/<name>/package.nix` (auto-discovered) |
| Tweak to an existing nixpkgs package | `overlays/default.nix` |
| User dotfile / program, cross-platform | `home/jhl/common/core/<name>.nix` + add to that dir's `default.nix` |
| User dotfile, macOS-only | `home/jhl/common/core/darwin/<name>.nix` + add to `common/core/darwin.nix` |
| Opt-in user feature | `home/jhl/common/optional/<cat>/<name>.nix`, imported by `home/jhl/<Host>.nix` |
| Per-host home tweak, no new file | `home/jhl/<Host>.nix` directly |
| Brand new machine | `hosts/darwin/<Host>/default.nix` + `home/jhl/<Host>.nix` (Recipe 7) |

The two tiers ("optional" file vs `modules/` module) exist because an optional file is just config — the fastest path when a feature is a single attrset a machine either wants or doesn't. A `modules/` module is right once two machines need the same feature with *different inputs*. Options give a typed interface and prevent copy-paste drift.

## Recipe 1: drop-in optional system feature

Pattern source: `hosts/common/optional/darwin/steam.nix`.

Create one file under `hosts/common/optional/darwin/`. It is a plain module — no `options` block:

```nix
{ ... }:
{
  darwinHomebrew.casks = [ "steam" ];
}
```

Enable it by adding the path to the host's imports:

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

Note `map lib.custom.relativeToRoot [ ... ]` takes **strings**, not path literals.

## Recipe 2: reusable module with options

Pattern source: `modules/hosts/darwin/homebrew/default.nix`.

Place at `modules/hosts/<platform>/<name>/default.nix`. Auto-imported — `modules/hosts/{common,nixos,darwin}/default.nix` each call `lib.custom.scanPaths ./.`.

```nix
{ config, lib, ... }:
let
  cfg = config.<name>;
  inherit (lib) mkOption types;
in
{
  options.<name> = {
    enable = mkOption { type = types.bool; default = true; description = "..."; };
    someList = mkOption { type = types.listOf types.str; default = [ ]; description = "..."; };
  };

  config = lib.mkIf cfg.enable {
    # ...
  };
}
```

A host turns it on by setting the option — no import:

```nix
# hosts/darwin/SeandeMac-Studio/default.nix
darwinHomebrew.macosBeta = true;
```

**Use `listOf` when several modules should contribute.** The module system concatenates definitions from every module, which is exactly how `hosts/common/core/darwin/apps.nix` supplies the fleet-wide cask list while `hosts/common/optional/darwin/steam.nix` appends one more. `attrsOf` merges by key the same way (`masApps`).

For a wider real example including a `nullOr path` option and an activation script, see `modules/hosts/darwin/wallpaper/default.nix`.

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

Function arguments are auto-supplied by `callPackage`. For Rust use `rustPlatform.buildRustPackage { ... cargoHash = ...; }`.

Consume anywhere as `pkgs.<name>`. Build standalone with `nix build .#packages.aarch64-darwin.<name>`.

Dropping the file is the only step — no flake edit, no overlay edit. Both the `additions` overlay and the `packages` output run `packagesFromDirectoryRecursive` over `pkgs/common`.

## Recipe 4: override a nixpkgs package

Edit `overlays/default.nix`. Five layers exist; you want one of three:

```nix
modifications = _final: prev: {
  foo = prev.foo.overrideAttrs (old: { patches = old.patches ++ [ ./fix.patch ]; });
};

linuxModifications = _final: prev: prev.lib.optionalAttrs prev.stdenv.isLinux {
  bar = _final.unstable.bar;
};
```

`lib.optionalAttrs` makes the attribute literally absent on macOS, which is stricter than `lib.mkIf` and prevents "unknown attribute" at evaluation.

**Just need a newer version?** Use `pkgs.unstable.<x>` — the `unstable-packages` layer already imports `nixpkgs-unstable` with `allowUnfree`. Don't write an override for that.

**Do not touch the `customLib` layer.** It puts `lib.custom` onto `pkgs.lib` so home-manager can reach it without losing `lib.hm`. See `architecture.md` § The two lib plumbing paths.

## Recipe 5: add a home-manager program or dotfile

### 5a. Cross-platform, always on

Create `home/jhl/common/core/<name>.nix`, then add `./<name>.nix` to the imports list in `home/jhl/common/core/default.nix`. That list is hand-written on purpose — it is the visible inventory of the dotfile surface.

Identity comes from the `hostSpec` **argument**, not `config`:

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

### 5b. macOS-only, always on

Create `home/jhl/common/core/darwin/<name>.nix` and add it to `home/jhl/common/core/darwin.nix`'s imports. Anything referencing `/opt/homebrew`, `targets.darwin.defaults`, or `osascript` belongs here rather than in a cross-platform file.

### 5c. Opt-in per host

Create `home/jhl/common/optional/<cat>/<name>.nix`, then name it in the host's home file:

```nix
# home/jhl/jhlsMacBookPro.nix
imports = [
  ./common/core
  ./common/optional/editors/zed.nix
];
```

### 5d. Per-host tweak, no new file

Edit `home/jhl/<Host>.nix` directly:

```nix
sshKeys.primary = "id_ykmini";
```

## Recipe 6: add a Homebrew package

Fleet-wide — append to the appropriate list in `hosts/common/core/darwin/apps.nix`:

```nix
darwinHomebrew = {
  brews = [ ... "newthing" ];
  casks = [ ... "new-app" ];
  taps  = [ { name = "owner/tap"; trusted = true; } ];
  masApps = { "App Name" = 1234567890; };
};
```

One machine only — make an optional file (Recipe 1) that appends to the same list, and import it from that host.

Three things to know:

- **`trusted = true` on non-official taps.** Homebrew 6.0 turned on `HOMEBREW_REQUIRE_TAP_TRUST`; a tap has to be trusted before activation can load its formulae. `trusted` emits `trusted: true` into the Brewfile, which `brew bundle` applies before the fetch phase — no manual `brew trust` on a new machine.
- **`masApps` is skipped on seed builds.** `modules/hosts/darwin/homebrew/` wraps it in `lib.optionalAttrs (!cfg.macosBeta)`. Run `just check-beta` on the machine to find out which it is; set `darwinHomebrew.macosBeta = true;` in the host file if it's a seed. `SeandeMac-Studio` currently is.
- **`onActivation.cleanup = "zap"`.** Anything not declared is uninstalled on the next switch.

## Recipe 7: add a host

Two files, no flake edit.

```nix
# hosts/darwin/<Name>/default.nix
{ lib, ... }:
{
  imports = map lib.custom.relativeToRoot [
    # "hosts/common/optional/darwin/steam.nix"
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

`hostName` must match the directory name — `hosts/common/users/jhl/darwin.nix` computes the home file path as `home/jhl/${config.hostSpec.hostName}.nix`, and `flake.nix` keys the configuration off the directory name.

Then, **on that Mac**, `just rebuild`. Remember `git add --intent-to-add` (or just let `just rebuild-pre` do it) or the flake won't see the new directory.

## Recipe 8: wire something that needs a secret

The Nix side is mechanical; the secret value is written by the user with `sops`.

`hosts/common/core/sops.nix` provides plumbing only — the sops-nix module import and `sops.age.keyFile`. It declares **no** secrets deliberately, so no machine fails to evaluate over a YAML key that hasn't been filled in yet.

Declare the secret in the module that consumes it:

```nix
{ config, inputs, ... }:
{
  sops.secrets."npm/jianyuelab_token" = {
    sopsFile = "${inputs.nix-secrets}/secrets/shared.yaml";
    owner = config.hostSpec.username;
    mode  = "0400";
  };
}
```

When the secret is one substring of a larger file format, use a template rather than `.path`:

```nix
sops.templates."npmrc" = {
  content = ''
    @jianyuelab:registry=https://npm.pkg.github.com
    //npm.pkg.github.com/:_authToken=${config.sops.placeholder."npm/jianyuelab_token"}
  '';
  owner = config.hostSpec.username;
  mode  = "0600";
  path  = "${config.hostSpec.home}/.npmrc";
};
```

Full worked example with the user-side steps: `hosts/common/optional/darwin/npmrc.nix`.

Then hand off: tell the user the exact YAML key path and which file (`shared.yaml` unless it's genuinely machine-specific), and that they need `just sops-edit shared`, a commit+push in `../nix-secrets`, and `just update-nix-secrets`.

**Verify after the first rebuild.** A decryption failure at switch time is loud — the install script is inlined into `activate`, which runs under `set -e`, so the switch aborts. The boot-time path (`launchd.daemons.sops-install-secrets`) is quieter. `just check-sops` asserts every declared secret actually landed in `/run/secrets`; `just verify-sops` with `hosts/common/optional/darwin/sops-canary.nix` proves the whole pipeline including templates and the launchd path.

## Recipe 9: add a user

There is no dedicated tooling; mirror `jhl`.

1. Copy `hosts/common/users/jhl/` to `hosts/common/users/<new>/`, keeping the three-file split. Nix does *not* auto-pick by platform — `hosts/common/core/default.nix` has to import both `"hosts/common/users/<new>"` and `"hosts/common/users/<new>/${platform}.nix"`.
2. Gate Linux-only attrs with `lib.optionalAttrs pkgs.stdenv.isLinux { group = "wheel"; }` so Darwin still evaluates.
3. Copy `home/jhl/` to `home/<new>/`, keeping `common/core/{default,darwin,nixos}.nix` and whichever `common/optional/` subtrees apply.
4. `hostSpec.username` is currently a single value set in `hosts/common/core/default.nix`. A genuinely multi-user setup needs that generalised — flag it rather than hacking around it.

## Common pitfalls

- **`relativeToRoot` takes a string.** `map lib.custom.relativeToRoot [ "hosts/common/core" ]`, never `./hosts/common/core`.
- **New files are invisible to the flake until `git add --intent-to-add`.** Flake source tracking ignores untracked files entirely. `just rebuild-pre` handles it; a bare `darwin-rebuild` does not.
- **`system.stateVersion`:** integer on Darwin, string on NixOS.
- **Don't put `lib` in `extraSpecialArgs`.** It drops `lib.hm`. See `architecture.md`.
- **`environment.systemPath` needs `lib.mkOrder 1100`,** not a plain definition and not `mkAfter`.
- **Don't interpolate a multi-line string at column 0 inside `''`.** Nix de-indents by the minimum indentation across lines, and a line beginning with `${...}` at column 0 makes that minimum 0 — so nothing is stripped and the generated file keeps its source indentation. `home/jhl/common/core/darwin/ssh-agent.nix` builds a single-line array to dodge this.
- **`lib.mkDefault` in shared layers, plain assignment in host files.** Reaching for `mkForce` in a shared file is a smell.
- **Home modules read `hostSpec` from the function head,** not from `config`. It is not declared as an option in the HM scope.
- **Changed `../nix-secrets`? Push it.** It's a locked remote input; local edits are invisible until pushed and re-locked.
