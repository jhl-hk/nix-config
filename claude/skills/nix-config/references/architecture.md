# Architecture & Mental Model

Why each value lands where it does — flake outputs, the `lib.custom` helpers, the two-file platform pattern, the `hostSpec` data bus, and the inheritance chain. Read this for the *why*; `recipes.md` has the *how*.

## Contents

- [Where do new modules go?](#where-do-new-modules-go)
- [flake.nix outputs](#flakenix-outputs)
- [The two lib plumbing paths](#the-two-lib-plumbing-paths)
- [lib/default.nix](#libdefaultnix)
- [The three-file pattern — three distinct uses](#the-three-file-pattern--three-distinct-uses)
- [Auto-discovery vs cherry-pick](#auto-discovery-vs-cherry-pick)
- [hostSpec — the data bus](#hostspec--the-data-bus)
- [Inheritance chain](#inheritance-chain)
- [Option merge order](#option-merge-order)
- [nix-secrets integration](#nix-secrets-integration)

## Where do new modules go?

| Intent | Directory |
|---|---|
| Home-Manager-only option | `modules/home/<name>.nix` |
| Cross-platform system option | `modules/hosts/common/<name>.nix` |
| macOS-only system option | `modules/hosts/darwin/<name>/default.nix` |
| Linux-only system option | `modules/hosts/nixos/<name>/default.nix` |
| Shared by both HM and system scope | `modules/common/` |

In every case: drop the file, `scanPaths` picks it up from the local `default.nix`. No registration. These define options; turning a feature on is still per-host or per-user.

## flake.nix outputs

Seven outputs: `overlays`, `darwinConfigurations`, `nixosConfigurations`, `packages`, `formatter`, `devShells`, `checks`.

**Host discovery.** `hostsIn` reads a directory and keeps only entries whose `type == "directory"`, guarded by `builtins.pathExists`:

```nix
hostsIn = dir:
  if builtins.pathExists dir
  then lib.attrNames (lib.filterAttrs (_: type: type == "directory") (builtins.readDir dir))
  else [ ];
```

The directory filter is load-bearing: `hosts/nixos/` contains only `.gitkeep` (git can't track empty directories), and without the filter that file would become a phantom host. `nixosConfigurations` currently evaluates to `{ }`.

Because flake source tracking ignores untracked files entirely, **a newly created host directory is invisible until `git add --intent-to-add`** runs. `just rebuild-pre` does this automatically.

**`darwinConfigurations`.** `lib.genAttrs (hostsIn ./hosts/darwin) mkDarwinHost`. Each host gets `specialArgs = { inherit inputs outputs; lib = darwinLib; isDarwin = true; }` and exactly three modules:

```nix
modules = [
  ./hosts/common/core          # must come first — see Option merge order
  ./hosts/darwin/${hostName}
  home-manager.darwinModules.home-manager
];
```

Everything else (platform core, users, home-manager wiring) hangs off `hosts/common/core/default.nix`. The home-manager *configuration* is not here — it lives in `hosts/common/users/jhl/darwin.nix`, because computing which home file to import requires reading `config.hostSpec.hostName`, and `flake.nix` has no `config`.

`specialArgs.isDarwin` is the bootstrap signal used before `hostSpec` is assembled. `config.hostSpec.isDarwin` is set *from* it in `hosts/common/core/default.nix`, so they agree, but they are not the same binding — reaching for `config.hostSpec.isDarwin` inside early-evaluated modules (sops) risks infinite recursion.

**`overlays`.** Five layers: `additions` (everything under `pkgs/common/`), `customLib`, `modifications`, `linuxModifications`, `unstable-packages`. Applied via `nixpkgs.overlays = builtins.attrValues outputs.overlays;` in `hosts/common/core/nix-settings.nix`. With `useGlobalPkgs = true`, home-manager sees the same `pkgs`.

**`packages`.** `forAllSystems` over `aarch64-darwin` and `x86_64-linux`, using the same `packagesFromDirectoryRecursive ./pkgs/common` scan as the `additions` overlay. The overlay is for internal refs (`pkgs.foo`); `packages` is for `nix build .#packages.<system>.foo`.

**`checks`.** `nix flake check` does not look at `darwinConfigurations`, so `checks.aarch64-darwin.darwin-<host>` maps each host's `.system` derivation in. This is what makes `just check` and CI actually build every machine rather than only type-check the flake.

**`devShells` / `formatter`.** `shell.nix` provides the dev shell (sops, age, ssh-to-age, just, gum, alejandra, deadnix, jq, yq-go). `alejandra` is the formatter.

## The two lib plumbing paths

`lib.custom` has to reach two different module systems, and **they need different mechanisms**. This is the single most confusing part of the repo; both failure modes were hit during the refactor.

**System scope — `specialArgs.lib`, extended per platform.**

```nix
mkLib = base: base.extend (self': _: { custom = import ./lib { lib = self'; }; });
lib       = mkLib nixpkgs.lib;         # NixOS hosts, forAllSystems, checks
darwinLib = mkLib nixpkgs-darwin.lib;  # Darwin hosts
```

Both bases are needed because nix-darwin compares the module system's `lib.trivial.release` against its own version. `nixpkgs` is unstable (26.11) while `nix-darwin` follows `nixpkgs-darwin` (26.05); passing the unstable-derived lib to `darwinSystem` produces:

```
nix-darwin 26.05 with Nixpkgs 26.11
```

**Home-manager scope — the `customLib` overlay, never `extraSpecialArgs`.**

Home-manager builds its own `lib` as `pkgs.lib.extend hmExtension`. Passing `lib` through `extraSpecialArgs` overrides that binding wholesale and drops `lib.hm`, so any HM module touching `lib.hm.*` (mako and many services do) fails with:

```
error: attribute 'hm' missing
```

The fix is to put `custom` on `pkgs.lib` instead, so HM's own extend picks it up and both survive:

```nix
customLib = _final: prev: {
  lib = prev.lib // { custom = import ../lib { inherit (prev) lib; }; };
};
```

Verified: inside an HM module, `lib ? custom` and `lib ? hm` are both true, and `lib.custom.relativeToRoot` resolves against the flake root.

## lib/default.nix

Two helpers.

**`relativeToRoot = lib.path.append ../.`** — takes a **string** like `"hosts/common/core"` and returns a path resolved against the flake root. Passing a path literal errors. Strings also keep the path stable as a store identifier.

**`scanPaths = path: ...`** — returns immediate children that are either directories or `.nix` files **other than `default.nix`**. The exclusion is load-bearing: `scanPaths` is called *from* a `default.nix`, so including itself would infinitely recurse.

## The three-file pattern — three distinct uses

Sibling `default.nix` / `darwin.nix` / `nixos.nix` appears three ways.

**(a) Platform-scoped directory.** Under `modules/hosts/{common,nixos,darwin}/`, the *directory* is the filter. `modules/hosts/darwin/<x>` is only seen by Macs because `hosts/common/core/default.nix` imports `modules/hosts/${platform}`. Each `default.nix` there is identical (`imports = lib.custom.scanPaths ./.;`) — that is the whole mechanism.

**(b) Coexisting siblings, internal pick.** Under `home/jhl/common/core/`, all three sit side by side and `default.nix` contains `./${platform}.nix` where `platform` derives from `hostSpec.isDarwin`. Renaming a sibling breaks evaluation only on the affected platform, silently.

**(c) External platform selection.** Under `hosts/common/core/` and `hosts/common/users/jhl/`, the platform sibling is chosen by an *outer* file. `hosts/common/core/default.nix` lists `"hosts/common/users/jhl"` and `"hosts/common/users/jhl/${platform}.nix"` as two separate entries. The user file does not interpolate `${platform}` itself.

Rule: directory named `nixos/`/`darwin/` → (a). A sibling `default.nix` containing `./${platform}.nix` → (b). Otherwise → (c).

## Auto-discovery vs cherry-pick

**Auto-discovered.** Hosts (`readDir ./hosts/{darwin,nixos}`). Packages (`packagesFromDirectoryRecursive ./pkgs/common`). Modules under `modules/**` (via `scanPaths`).

**Cherry-picked.** `hosts/common/optional/**` — each host enumerates what it wants. `home/jhl/common/core/default.nix` imports — listed by hand so the dotfile surface is visible at a glance. `home/jhl/common/optional/**` — named by the per-host home file.

Rule of thumb: auto-load when a `default.nix` calls `scanPaths`; cherry-pick when it lists imports by hand. Directory names like `common` or `core` are hints, not guarantees.

## hostSpec — the data bus

Declared in `modules/common/host-spec.nix` as one `submodule` option with `freeformType = attrsOf str` (an escape hatch for undeclared string keys only — declared options keep their stricter types).

Populated in two places: `hosts/common/core/default.nix` sets `username`, `handle`, `isDarwin` and `inherit`s the rest from `inputs.nix-secrets`; each `hosts/darwin/<host>/default.nix` sets `hostName` and per-machine flags.

Modules read `config.hostSpec.<field>` — never `inputs.nix-secrets`. Because the same option is declared into both the Darwin and (future) NixOS scopes, hostSpec is the only platform-agnostic data bus in the repo.

Home-manager is the exception: `hostSpec` arrives as a **function argument** through `extraSpecialArgs`, and `modules/common/host-spec.nix` is deliberately *not* imported into the HM scope. Home modules destructure `{ hostSpec, ... }`.

Full option enumeration: `hostspec.md`.

## Inheritance chain

```
flake.nix
  └─ darwin.lib.darwinSystem { specialArgs = { inputs outputs; lib = darwinLib; isDarwin = true; }; }
       modules = [ ./hosts/common/core, ./hosts/darwin/<host>, hm.darwinModules ]
          │
          ├─ hosts/common/core/default.nix
          │     ├─ modules/common          (scanPaths → host-spec option)
          │     ├─ modules/hosts/common    (scanPaths)
          │     ├─ modules/hosts/darwin    (scanPaths → homebrew, wallpaper)
          │     ├─ hosts/common/core/darwin.nix        (platform pick, case c)
          │     │     ├─ ./darwin/system-defaults.nix
          │     │     └─ ./darwin/apps.nix             (darwinHomebrew.* data)
          │     ├─ hosts/common/core/nix-settings.nix  (nixpkgs.overlays)
          │     ├─ hosts/common/core/sops.nix          (sops plumbing, no secrets)
          │     ├─ hosts/common/users/jhl              (shell, Linux-gated attrs)
          │     └─ hosts/common/users/jhl/darwin.nix   (platform pick, case c)
          │           └─ home-manager.users.jhl.imports
          │                 └─ home/jhl/<host>.nix
          │                       ├─ ./common/core
          │                       │     ├─ modules/home        (scanPaths → sshKeys)
          │                       │     ├─ ./darwin.nix        (platform pick, case b)
          │                       │     │     └─ ./darwin/{keyboard,stats,ssh-agent}.nix
          │                       │     └─ ./git.nix ./ssh.nix ./zsh.nix …
          │                       └─ ./common/optional/editors/*.nix
          │
          └─ hosts/darwin/<host>/default.nix
                └─ hosts/common/optional/darwin/*.nix    (cherry-picked)
```

`specialArgs` carries flake-level bindings into top-level modules; `extraSpecialArgs` is the parallel mechanism for home-manager submodules.

## Option merge order

Two places where definition order changes the result, both discovered the hard way.

**`environment.systemPath`.** nix-darwin (`modules/environment/default.nix:139`) defines it twice:

```nix
environment.systemPath = mkMerge [
  [ (makeBinPath cfg.profiles) ]                              # order 1000 (default)
  (mkOrder 1200 [ "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin" ])
];
```

A plain definition is also order 1000, so it sorts by module position — and module position changes whenever imports are reordered. `hosts/common/core/darwin.nix` therefore uses `lib.mkOrder 1100`, pinning Homebrew's paths between the Nix profiles and `/usr/bin` regardless of module order. `lib.mkAfter` is 1500 and lands *after* `/usr/bin`, which lets Xcode's `/usr/bin/git` shadow Homebrew's.

**Module list order in `flake.nix`.** `./hosts/common/core` is listed before `./hosts/darwin/<host>` so the host file's definitions merge later. Keep it that way.

## nix-secrets integration

Pinned as a flake input:

```nix
nix-secrets.url = "git+ssh://git@github.com/jhl-hk/nix-secrets.git?ref=main&shallow=1";
```

It is a **locked remote input** — local edits in `../nix-secrets` are invisible to `.#<host>` evaluation until pushed and re-locked. `just update-nix-secrets` (run automatically by `just rebuild`) does the fetch/rebase/re-lock; the push is manual.

Top-level attributes (`domain`, `email`, `userFullName`, `sshAllowedSigners`, `networking`, `networkInfo`, `serviceInfo`) flow into `hostSpec` through the `inherit` in `hosts/common/core/default.nix`. Encrypted material lives in `secrets/*.yaml` and is decrypted at activation by sops-nix using `~/.config/sops/age/keys.txt`.

If the input can't resolve, evaluation dies at the `inherit` line with `attribute 'domain' missing`. The fix is always to make the input resolve — never to comment out the `inherit`, which would silently zero every consumer.
