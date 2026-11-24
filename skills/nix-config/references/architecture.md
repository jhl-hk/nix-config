# Architecture

`hostSpec` fields: `hostspec.md`. Secrets: `nix-secrets.md`. Where a new file goes: `recipes.md` § Decision tree.

## Contents

- [flake.nix inputs and outputs](#flakenix-inputs-and-outputs)
- [The two lib plumbing paths](#the-two-lib-plumbing-paths)
- [lib/default.nix](#libdefaultnix)
- [Platform siblings — three distinct uses](#platform-siblings--three-distinct-uses)
- [Auto-discovery vs cherry-pick](#auto-discovery-vs-cherry-pick)
- [Inheritance chain](#inheritance-chain)
- [Option merge order](#option-merge-order)
- [Agent tooling](#agent-tooling)

## flake.nix inputs and outputs

**Inputs that shape evaluation.**

| Input | Used by |
|---|---|
| `nixpkgs` (unstable) | `lib`, NixOS and standalone `pkgs`, `packages`, checks |
| `nixpkgs-darwin` (26.05) | `darwinLib`; `darwin` follows it |
| `darwin` (nix-darwin-26.05) | `mkDarwinHost` |
| `home-manager` (release-26.05) | `home-manager.darwinModules.home-manager` |
| `home-manager-unstable` (master) | `mkNixosHost` (`nixosModules.home-manager`), `mkHomeHost` (`lib.homeManagerConfiguration`) |
| `sops-nix` | `hosts/common/core/sops.nix`, `home/jhl/common/optional/sops/standalone.nix` |
| `nix-secrets` (private, ssh) | `hostSpec` data, `secrets/*.yaml`, `agents/AGENTS.md` |
| `jianyuelab-docs`, `jianyuelab-plugins` (private, ssh, `flake = false`) | `skills.nix`, `omp.nix` jyl-memory hook |
| `wakatime-omp`, `notchnotch`, `notchnotch-agents` (`flake = false`) | `omp.nix`, `darwin/notchnotch.nix` |

Private ssh inputs mean `just check` needs SSH auth to github.com.

**Outputs.** `overlays`, `darwinConfigurations`, `nixosConfigurations`, `homeConfigurations`, `packages`, `formatter`, `devShells`, `checks`.

**Host discovery.** `hostsIn` keeps only subdirectories, so placeholder files never become hosts:

```nix
hostsIn = dir:
  if builtins.pathExists dir
  then lib.attrNames (lib.filterAttrs (_: type: type == "directory") (builtins.readDir dir))
  else [ ];
```

Applied to `hosts/darwin`, `hosts/nixos` and `hosts/home`.

**`mkDarwinHost`** (`aarch64-darwin`). `specialArgs = { inherit inputs outputs; lib = darwinLib; isDarwin = true; }`:

```nix
modules = [
  ./hosts/common/core          # must come first — see Option merge order
  ./hosts/darwin/${hostName}
  home-manager.darwinModules.home-manager
];
```

**`mkNixosHost`** (`x86_64-linux`, `nixpkgs.lib.nixosSystem`). `specialArgs = { inherit inputs outputs lib; isDarwin = false; }`; modules `./hosts/common/core`, `./hosts/nixos/${hostName}`, `home-manager-unstable.nixosModules.home-manager`.

On both system lanes the home-manager configuration lives in `hosts/common/users/jhl/<platform>.nix`, because the home file path needs `config.hostSpec.hostName`. It sets `useGlobalPkgs`, `useUserPackages`, `backupFileExtension = "backup"` and `extraSpecialArgs = { inputs outputs; isDarwin; hostSpec = config.hostSpec; }`.

`specialArgs.isDarwin` is the bootstrap signal before `hostSpec` exists; `config.hostSpec.isDarwin` is set from it. Use the specialArg in early modules (sops, platform dispatch) to avoid infinite recursion.

**`mkHomeHost`** (`x86_64-linux`). Keyed `"<user>@<Host>"` (what `home-manager switch --flake .#jhl@<Host>` and `nh home -c` expect). It:

1. builds `pkgs` from `nixpkgs` with all overlays and `allowUnfree` (no `nix-settings.nix` on this lane);
2. evaluates `hostSpec` with `lib.custom.evalHostSpec` over `hosts/common/core/host-spec.nix` + `hosts/home/<Host>`;
3. calls `home-manager-unstable.lib.homeManagerConfiguration` with top-level `lib`, `extraSpecialArgs = { inputs outputs hostSpec; isDarwin = false; }` and one module, `./home/<user>/<Host>.nix`.

**`overlays`.** `additions` (`pkgs/common/`), `customLib`, `modifications`, `linuxModifications`, `unstable-packages`. System lanes apply them in `hosts/common/core/nix-settings.nix`; `useGlobalPkgs` hands the same `pkgs` to home-manager.

**`packages`.** `forAllSystems` (`aarch64-darwin`, `x86_64-linux`) over `packagesFromDirectoryRecursive ./pkgs/common`.

**`checks`.** `nix flake check` ignores configuration outputs, so they are mapped in per system:

| System | Check name | Derivation |
|---|---|---|
| `aarch64-darwin` | `darwin-<Host>` | `.system` |
| `x86_64-linux` | `nixos-<Host>` | `.config.system.build.toplevel` |
| `x86_64-linux` | `home-<user>-at-<Host>` (`@` → `-at-`) | `.activationPackage` |

`--all-systems` evaluates every machine and builds the native ones.

**`devShells` / `formatter`.** `shell.nix`; `alejandra`.

## The two lib plumbing paths

`lib.custom` reaches two module systems through different channels.

**System scope — `specialArgs.lib`, extended per platform.**

```nix
mkLib = base: base.extend (self': _: { custom = import ./lib { lib = self'; }; });
lib       = mkLib nixpkgs.lib;         # NixOS, standalone, forAllSystems, checks
darwinLib = mkLib nixpkgs-darwin.lib;  # Darwin hosts
```

nix-darwin compares `lib.trivial.release` against its own version; the unstable lib (26.11) against nix-darwin 26.05 aborts with:

```
nix-darwin 26.05 with Nixpkgs 26.11
```

**Home-manager scope — the lib home-manager extends, never `extraSpecialArgs`.**

Home-manager evaluates modules with

```nix
extendedLib = import modules/lib/stdlib-extended.nix lib;   # = lib.extend (…: { hm = …; })
```

over the `lib` it was handed.

- `lib` in `extraSpecialArgs` replaces that result: `lib.hm` disappears and HM modules using `lib.hm.*` fail with `error: attribute 'hm' missing`.
- The handed-in lib must already carry `custom`; `stdlib-extended` extends, so it survives next to `hm`.

| Lane | Channel |
|---|---|
| nix-darwin / NixOS | `specialArgs.lib`; HM's `nixos/common.nix` reads the system module's `lib` |
| standalone | top-level `lib` argument of `home-manager-unstable.lib.homeManagerConfiguration` |

**`pkgs.lib` is not a channel.** The `customLib` overlay adds `custom` with `//`, outside the fixpoint; `.extend` rebuilds from the fixpoint and drops it:

```
pkgs.lib ? custom                                   => true
(pkgs.lib.extend (_: _: {})) ? custom               => false
(stdlib-extended pkgs.lib) ? custom                 => false     # what HM does
(stdlib-extended pkgs.lib) ? hm                     => true
```

A `homeManagerConfiguration` without `lib` defaults to `pkgs.lib` and fails at the first `lib.custom.relativeToRoot` with `attribute 'custom' missing`. The overlay stays for code that reads `pkgs.lib` directly.

## lib/default.nix

- **`relativeToRoot = lib.path.append ../.`** — takes a **string** (`"hosts/common/core"`) and returns a path under the flake root. A path literal errors. Call form: `map lib.custom.relativeToRoot [ "hosts/common/core" ]`.
- **`scanPaths path`** — immediate children that are directories or `.nix` files other than `default.nix` (it is called from a `default.nix`; including itself would recurse).
- **`evalHostSpec`** — `evalModules` over `modules/common/host-spec.nix` plus the given modules; returns the `hostSpec` attrset for the standalone lane.

## Platform siblings — three distinct uses

**(a) Platform-scoped directory.** `modules/hosts/{common,nixos,darwin}/`: the directory is the filter. `hosts/common/core/default.nix` imports `modules/hosts/${platform}` with `platform = if isDarwin then "darwin" else "nixos"`. Each `default.nix` there is `imports = lib.custom.scanPaths ./.;`.

**(b) Coexisting siblings, internal pick.** `home/jhl/common/core/default.nix` imports `./${platform}.nix` with `platform = if hostSpec.isDarwin then "darwin" else "linux"`. `linux.nix` loads on NixOS and standalone hosts. Renaming a sibling breaks only that platform.

**(c) External selection.** In `hosts/common/core/` and `hosts/common/users/jhl/`, an outer file picks: `hosts/common/core/default.nix` lists `"hosts/common/core/${platform}.nix"`, `"hosts/common/users/jhl"` and `"hosts/common/users/jhl/${platform}.nix"` separately.

Rule: directory named `nixos/`/`darwin/` → (a). `default.nix` containing `./${platform}.nix` → (b). Otherwise → (c).

## Auto-discovery vs cherry-pick

| Auto-discovered | Mechanism |
|---|---|
| Hosts | `hostsIn` over `hosts/{darwin,nixos,home}` |
| Packages | `packagesFromDirectoryRecursive ./pkgs/common` |
| `modules/**` | `scanPaths` |
| Skills | `skills.nix` scans `skills/` for `<name>/SKILL.md` |

| Cherry-picked | Picked by |
|---|---|
| `hosts/common/optional/**` | the host's `imports` |
| `home/jhl/common/core/*.nix` | hand-written list in `home/jhl/common/core/default.nix` |
| `home/jhl/common/core/darwin/*.nix` | `home/jhl/common/core/darwin.nix` |
| `home/jhl/common/optional/**` | `home/jhl/<Host>.nix` |

Auto-load when a `default.nix` calls `scanPaths`; cherry-pick when it lists imports. Directory names (`common`, `core`) are not a guarantee.

## Inheritance chain

```
flake.nix
  ├─ mkDarwinHost / mkNixosHost
  │    modules = [ ./hosts/common/core, ./hosts/<lane>/<host>, <hm>.<platform>Modules.home-manager ]
  │      ├─ hosts/common/core/default.nix              (vim git curl wget)
  │      │     ├─ modules/common                       (host-spec option)
  │      │     ├─ modules/hosts/common
  │      │     ├─ modules/hosts/${platform}            (darwin: homebrew, omni, wallpaper, yubikey)
  │      │     ├─ hosts/common/core/${platform}.nix    (case c)
  │      │     │     darwin.nix → ./darwin/{system-defaults,apps,local-dns,ssh-shared-key,forgejo}.nix
  │      │     │     nixos.nix  → hostName, zsh, terminfo, stateVersion
  │      │     ├─ hosts/common/core/host-spec.nix      (hostSpec population)
  │      │     ├─ hosts/common/core/nix-settings.nix   (nixpkgs.overlays)
  │      │     ├─ hosts/common/core/sops.nix           (sops plumbing, no secrets)
  │      │     ├─ hosts/common/users/jhl
  │      │     └─ hosts/common/users/jhl/${platform}.nix
  │      │           └─ home-manager.users.jhl.imports = [ home/jhl/<host>.nix ]
  │      └─ hosts/<lane>/<host>/default.nix
  │            └─ hosts/common/optional/{darwin,nixos,common}/*.nix   (cherry-picked)
  │
  └─ mkHomeHost
       hostSpec = evalHostSpec [ hosts/common/core/host-spec.nix, hosts/home/<host> ]
       modules  = [ home/jhl/<host>.nix ]

home/jhl/<host>.nix
  ├─ ./common/core/default.nix
  │     ├─ modules/home                (scanPaths: ssh-keys, llm, mcp-servers)
  │     ├─ ./${platform}.nix           (case b)
  │     │     darwin.nix → ./darwin/{keyboard,stats,ssh-agent,ghostty,git-homebrew,notchnotch}.nix
  │     │     linux.nix  → fonts and Linux-only settings
  │     └─ ./git.nix ./nh.nix ./ssh.nix ./bash.nix ./zsh.nix ./starship.nix ./zoxide.nix
  │        ./vim.nix ./yazi.nix ./tmux.nix ./agent-instructions.nix ./skills.nix
  │        ./cloudflare.nix ./jyl-memory.nix ./llm.nix ./wakatime.nix ./typst.nix
  └─ ./common/optional/<cat>/*.nix     (ai, desktop, editors, k8s, nix, shell, sops)
```

`specialArgs` carries flake bindings into system modules; `extraSpecialArgs` carries them into home-manager modules.

## Option merge order

**`environment.systemPath`.** nix-darwin (`modules/environment/default.nix:139`):

```nix
environment.systemPath = mkMerge [
  [ (makeBinPath cfg.profiles) ]                              # order 1000 (default)
  (mkOrder 1200 [ "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin" ])
];
```

A plain definition is also 1000 and sorts by module position, which moves when imports are reordered. `hosts/common/core/darwin.nix` uses `lib.mkOrder 1100` to pin Homebrew between the Nix profiles and `/usr/bin`. `lib.mkAfter` (1500) lands after `/usr/bin`, so Xcode's `/usr/bin/git` shadows Homebrew's.

**Module list order in `flake.nix`.** `./hosts/common/core` precedes `./hosts/<lane>/<host>` so host definitions merge later. Keep it.

## Agent tooling

| File | Does |
|---|---|
| `home/jhl/common/optional/ai/omp.nix` | omp, the only coding agent configured. Imported by jhlsMacBookPro, SeandeMac-Studio, jhlsRogZephyrus, jhlsTokyoDesktop. Binary: `can1357/tap/omp` brew in `dev-extras.nix` on Macs, distro package on Linux. |
| `home/jhl/common/core/agent-instructions.nix` | Links `${nix-secrets}/agents/AGENTS.md` to `~/.omp/agent/AGENTS.md` (read-only; edit in nix-secrets). |
| `home/jhl/common/core/skills.nix` | Links skills to `~/.agents/skills/<name>` (Recipe 11). |
| `modules/home/mcp-servers.nix` | Option `mcpServers.<name>.url`: shared remote HTTP list (`passport-admin`, `cloudflare-api`, `uptime`, `memory`, `google-workspace`). |
| `modules/home/llm.nix` | Options `llm.*`: provider facts (`apiUrl`, `models`, `envVar`, `apiKeyFile`) shared by omp and Zed. |
| `home/jhl/common/core/llm.nix` | Provider instance; reads `llm/*.json` model lists; exports the key in zsh, via `launchctl setenv` (Darwin) or a systemd user service (Linux). |
| `home/jhl/common/core/wakatime.nix` | Installs `pkgs.unstable.wakatime-cli`; writes `~/.wakatime.cfg` with `api_key_vault_cmd` reading `wakatime.apiKeyFile`. |
| `home/jhl/common/core/jyl-memory.nix` | jyl-memory plugin; its omp hook is linked by `omp.nix`. |

`omp.nix` writes:

| Path | Content |
|---|---|
| `~/.omp/agent/nix.yml` | Settings overlay, loaded via `PI_CONFIG_FILES`; outranks omp's own `config.yml`, which omp keeps writing. Sets `modelRoles.default`, `task.perCallModel = "on"`, theme, status line, no auto-update. A missing or invalid overlay is a startup error; `PI_CONFIG_FILES` reaches only shells started after a switch. |
| `~/.omp/agent/models.yml` | Providers from `llm.providers` with a non-empty model list; `apiKey` is the env var name. |
| `~/.omp/agent/mcp.json` | Not linked: activation merges `omp.mcpServers` into it by name (Recipe 10). |
| `~/.omp/agent/hooks/post/jyl-memory.ts` | From `jianyuelab-plugins`. |
| `~/.omp/agent/extensions/wakatime.ts` | From `wakatime-omp`; uses the `wakatime-cli` on PATH. |
| `~/.omp/agent/extensions/notchnotch.ts`, `~/Library/Application Support/NotchNotch/Plugins/co.jianyuelab.notchnotch.omp` | Macs only (`hostSpec.isDarwin`), from `notchnotch`. |
