---
name: nix-config
description: Operates jhl's nix-darwin monorepo at /Users/jhl/Documents/nix-src/{nix-config,nix-secrets}. Use when adding or editing a Darwin host, a system module, a home-manager program or dotfile, a shell config, a Homebrew brew/cask/masApp, a custom package, an overlay, or a sops secret; when wiring hostSpec from nix-secrets; when touching files under hosts/, home/, modules/, lib/, pkgs/, overlays/, claude/, assets/, flake.nix, or justfile; when running just (rebuild, build, check, check-beta, update, clean, sops-edit, rekey), darwin-rebuild, nix flake check, or sops; when debugging hostSpec assertions, scanPaths auto-imports that did not fire, imports that did not take effect, system.stateVersion type errors (int on Darwin, string on NixOS), environment.systemPath ordering, lib.hm missing in home-manager, Homebrew zap cleanup removing apps, masApps failing on a macOS seed build, or silent sops decryption failures; whenever a .nix file in this repo is the target, even when the user just says "add module", "add app", or "rebuild".
---

# nix-config

Operating manual for `/Users/jhl/Documents/nix-src/nix-config` (public logic) and `/Users/jhl/Documents/nix-src/nix-secrets` (private data, separate flake input). Currently **Darwin-only**: three Macs — `jhlsMacBookPro`, `jhlsMacBookAir`, `SeandeMac-Studio` — one user, `jhl`. The NixOS lane exists as an empty skeleton (`hosts/nixos/`, `modules/hosts/nixos/`, `hosts/common/core/nixos.nix`, `hosts/common/users/jhl/nixos.nix`) so a Linux box drops in without restructuring.

## Core mental model

Three composition lanes, all wired through one data bus.

**Lane 1 — Hosts.** Each host is `hosts/darwin/<HostName>/default.nix`, a thin file: it sets `hostSpec.hostName` plus this machine's overrides, then cherry-picks from `hosts/common/optional/`. `flake.nix` discovers hosts by `readDir ./hosts/darwin`, filtered to directories — **dropping a directory there creates a machine, no flake edit**. `hosts/common/core` is mandatory and is where platform dispatch and hostSpec population happen.

**Lane 2 — Home.** Each `(user, host)` pair is `home/jhl/<HostName>.nix`, importing `common/core` plus selected `common/optional/<cat>`. `home/jhl/common/core/default.nix` picks the platform variant via `./${platform}.nix` where `platform = if hostSpec.isDarwin then "darwin" else "nixos"` — a normal Nix import, not magic.

**Lane 3 — Modules.** Reusable options-providing modules live under `modules/hosts/{common,nixos,darwin}/` and `modules/home/`, auto-imported by `lib.custom.scanPaths` from the sibling `default.nix`. Dropping a `.nix` file (or a directory containing `default.nix`) wires it in. The module exposes `options.<name>`; a host turns it on by setting that option, not by importing the file.

**The data bus.** `modules/common/host-spec.nix` declares the `hostSpec` option tree. `hosts/common/core/default.nix` populates it once:

```nix
hostSpec = {
  username = "jhl";
  handle   = "jhl-hk";
  inherit isDarwin;
  inherit (inputs.nix-secrets)
    domain email userFullName sshAllowedSigners
    networking networkInfo serviceInfo;
};
```

After that, every host, module, and home file reads `config.hostSpec.<x>`. Home modules receive it as a **function argument** via `extraSpecialArgs` — destructure `{ hostSpec, ... }` at the function head rather than reaching into `config`. Module code must never touch `inputs.nix-secrets` directly; that indirection is why secrets can be swapped, audited, or stubbed in one place.

**Two distinct uses of `default.nix + darwin.nix + nixos.nix`.** Confusing them is the most common modeling error:

- In `modules/hosts/{common,nixos,darwin}/`, the *directory* is the platform filter — `modules/hosts/darwin/foo/` is only loaded on Macs because `hosts/common/core/default.nix` imports `modules/hosts/${platform}`.
- In `home/jhl/common/core/`, all three coexist and `default.nix` imports `./${platform}.nix` itself.
- In `hosts/common/core/` and `hosts/common/users/jhl/`, the platform sibling is selected by an **outer** file — `hosts/common/core/default.nix` lists both `"hosts/common/users/jhl"` and `"hosts/common/users/jhl/${platform}.nix"` as separate entries.

## Quick recipes

Recipe numbers match `references/recipes.md` 1-to-1. Pick the first match:

1. System feature only some Macs want, no options needed → Recipe 1 (drop-in optional).
2. System feature with configurable options → Recipe 2 (reusable module).
3. Package not in nixpkgs → Recipe 3.
4. Override a nixpkgs package → Recipe 4.
5. Home-manager dotfile or program → Recipe 5.
6. Homebrew brew / cask / masApp → Recipe 6.
7. New host → Recipe 7.
8. Something that needs a secret → Recipe 8.

### Recipe 1 — drop-in optional system feature

Create `hosts/common/optional/darwin/<name>.nix` as a config-only module, then add the path to the host's imports:

```nix
# hosts/darwin/<HostName>/default.nix
imports = map lib.custom.relativeToRoot [
  "hosts/common/optional/darwin/<name>.nix"
];
```

Why: `hosts/common/optional/` is deliberately **not** auto-scanned. The host file is the single audit point that tells you what a machine actually runs. Real example: `hosts/common/optional/darwin/steam.nix` (two lines — it just appends to `darwinHomebrew.casks`).

### Recipe 2 — reusable module with options (preferred for anything configurable)

Place at `modules/hosts/darwin/<name>/default.nix` (or `common/` for cross-platform). Standard shape:

```nix
{ config, lib, ... }:
let cfg = config.<name>;
in {
  options.<name> = {
    enable = lib.mkEnableOption "<name>";
    # ... typed options
  };
  config = lib.mkIf cfg.enable { /* ... */ };
}
```

Auto-imported by `scanPaths`. The host enables it with `<name>.enable = true;` — no import line. Live examples: `modules/hosts/darwin/homebrew/` (the whole Homebrew surface) and `modules/hosts/darwin/wallpaper/`.

Use this over Recipe 1 whenever the feature has parameters, or whenever more than one machine needs it with different inputs.

### Recipe 3 — add a custom package

Create `pkgs/common/<name>/package.nix` with a derivation. Auto-discovered by `packagesFromDirectoryRecursive` in both `flake.nix` (`packages` output) and `overlays/default.nix` (`additions` layer). Available as `pkgs.<name>` everywhere and as `nix build .#packages.aarch64-darwin.<name>`. Dropping the file is the only step.

### Recipe 4 — override a nixpkgs package

Edit `overlays/default.nix`. Slots: `modifications` (all platforms), `linuxModifications` (Linux only, uses `lib.optionalAttrs` so the attribute is literally absent elsewhere). To just get a newer version, prefer `pkgs.unstable.<x>` over an override — the `unstable-packages` layer already exposes it.

Do **not** touch the `customLib` layer unless you know why it exists — see Critical conventions.

### Recipe 5 — add a home-manager program or dotfile

Three placements, by reach:

1. *Cross-platform, always on* → `home/jhl/common/core/<name>.nix`, then add `./<name>.nix` to `home/jhl/common/core/default.nix` imports. Example: `git.nix`.
2. *macOS-only, always on* → `home/jhl/common/core/darwin/<name>.nix`, then add it to `home/jhl/common/core/darwin.nix` imports. Examples: `keyboard.nix`, `stats.nix`, `ssh-agent.nix`.
3. *Opt-in per host* → `home/jhl/common/optional/<cat>/<name>.nix`, then add the import to `home/jhl/<HostName>.nix`. Example: `common/optional/editors/zed.nix`.

Core is the always-on baseline; optional gives per-host granularity. The `<HostName>.nix` file is the order ticket.

### Recipe 6 — add a Homebrew package

Fleet-wide → append to the right list in `hosts/common/core/darwin/apps.nix` (`darwinHomebrew.brews` / `.casks` / `.taps` / `.masApps`). One machine only → make a `hosts/common/optional/darwin/<name>.nix` that appends to `darwinHomebrew.casks` and import it from that host.

`taps`/`brews`/`casks` are `listOf`, so definitions from any number of modules concatenate. `masApps` is `attrsOf int` and merges by attribute.

**`onActivation.cleanup = "zap"`** — anything not declared gets uninstalled on the next switch. A manual `brew install` is temporary.

### Recipe 7 — add a host

Create `hosts/darwin/<Name>/default.nix` (just `hostSpec.hostName` plus overrides) and `home/jhl/<Name>.nix`. No `flake.nix` edit — `readDir` finds it. Then run `just rebuild` on that Mac.

### Recipe 8 — wire something that needs a secret

`hosts/common/core/sops.nix` does the plumbing only (module import + `sops.age.keyFile`); it declares **no** secrets, so a machine never fails to evaluate over a YAML key that isn't filled in yet. Declare the secret in its consumer:

```nix
sops.secrets."<path/in/yaml>" = {
  sopsFile = "${inputs.nix-secrets}/secrets/shared.yaml";
  owner = config.hostSpec.username;
  mode  = "0400";
};
```

For rendered files where the secret is one substring of a larger format (netrc, `.npmrc`, env files), use `sops.templates` with `config.sops.placeholder."<path>"`. Pattern source: `hosts/common/optional/darwin/npmrc.nix`.

The YAML itself is user-operated — tell the user the exact key path and file, then stop. See "What NOT to do" in `references/nix-secrets.md`.

## Critical conventions

- **`system.stateVersion` types differ by platform.** nix-darwin wants an integer (`6`); NixOS wants a string (`"25.05"`). Mixing them throws a type error. The value tracks the *initial* install and pins migrations, not the running version — never bump it without reading release notes.
- **`lib.custom.relativeToRoot` takes a string, not a Path literal.** `relativeToRoot "hosts/common/core"` works; `relativeToRoot ./hosts/common/core` fails. The repo always wraps it as `map lib.custom.relativeToRoot [ "a" "b" ]`.
- **`scanPaths` auto-imports, `optional/` does not.** `modules/**` lights up the moment a file lands. `hosts/common/optional/**` is inert until a host names it. Modules define capabilities; optionals describe one machine's choices.
- **`environment.systemPath` must use `lib.mkOrder 1100`.** nix-darwin defines the Nix profile paths at default order 1000 and `/usr/local/bin:/usr/bin:...` at `mkOrder 1200` (`modules/environment/default.nix:139`). A plain definition is also 1000, so it sorts by module position and drifts when imports are reordered — putting Homebrew ahead of Nix. `mkAfter` (1500) overshoots and puts it behind `/usr/bin`, where Xcode's `/usr/bin/git` wins. 1100 is the only correct answer.
- **Never pass `lib` in `home-manager.extraSpecialArgs`.** HM's `lib` is `pkgs.lib.extend hmExtension`; overriding it drops `lib.hm` and every HM module using `lib.hm.*` dies with `attribute 'hm' missing`. `lib.custom` reaches HM through the `customLib` overlay layer, which adds `custom` to `pkgs.lib` so both survive. The system scope gets it separately via `specialArgs.lib`.
- **The system `lib` must be extended per platform.** `flake.nix` builds `darwinLib = mkLib nixpkgs-darwin.lib` separately from `lib = mkLib nixpkgs.lib`. Feeding the unstable lib to `darwinSystem` makes nix-darwin read `lib.trivial.release = 26.11` and abort with a version-mismatch error against its own 26.05.
- **Don't interpolate multi-line strings at column 0 inside `''`.** Nix de-indents by the minimum indentation across lines; a line starting with `${...}` at column 0 makes that minimum 0, so nothing is stripped and the generated file keeps its source indentation. Build a single-line value instead — see `home/jhl/common/core/darwin/ssh-agent.nix`.
- **Darwin users have no `group` attribute.** Gate Linux-only attrs with `lib.optionalAttrs pkgs.stdenv.isLinux { group = "wheel"; }` — see `hosts/common/users/jhl/default.nix`.
- **`lib.mkDefault` in base layers, plain assignment in host files.** `hosts/common/core/darwin.nix` sets `darwinWallpaper` with `mkDefault` so a host can override with a bare assignment.
- **Home modules take `hostSpec` as an argument, not from `config`.** It arrives via `extraSpecialArgs`; `modules/common/host-spec.nix` is deliberately *not* imported into the HM scope.
- **Secrets are user-operated.** This skill writes Nix that references `sops.secrets."<path>"` and names the YAML key. It does not run `sops`, edit `.sops.yaml`, generate age keys, or rekey.

## Commands cheat sheet

```
just rebuild        # switch current host; auto-runs update-nix-secrets before and check-sops after
                    # (rebuild/build/rebuild-trace go through scripts/rebuild.sh: bootstraps a fresh Mac, prefers nh)
just build          # build without activating
just check          # nix flake check --all-systems (the checks output really builds every Mac)
just diff           # git diff minus flake.lock
just update         # nix flake update + brew update/upgrade
just check-beta     # is this Mac on a seed build? (drives darwinHomebrew.macosBeta)
just sops-edit shared   # edit ../nix-secrets/secrets/shared.yaml
just rekey          # re-encrypt every secrets/*.yaml after editing .sops.yaml
nix develop         # shell with sops, age, ssh-to-age, just, gum, alejandra, deadnix
```

Full catalog: `references/commands.md`.

## References

Read on demand; each is self-contained.

- `references/recipes.md` — **the main reference.** Decision tree plus full file templates for every "add X" task, and the edge cases. Read before touching files.
- `references/architecture.md` — `flake.nix` outputs, `lib.custom` semantics, auto-import vs cherry-pick mechanics, the inheritance chain, and why the two `lib` plumbing paths exist. Read when something imports unexpectedly or a module fails to load.
- `references/hostspec.md` — complete `hostSpec` option enumeration with types, defaults, and which file populates which field.
- `references/nix-secrets.md` — the `nix-secrets` schemas, `.sops.yaml` structure, and the consumption patterns. Reference-only; the user edits these files.
- `references/commands.md` — full `justfile` catalog and the rebuild flow.
