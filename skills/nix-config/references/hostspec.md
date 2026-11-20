# hostSpec Reference

## Contents

- [What hostSpec is](#what-hostspec-is)
- [Options: identity](#options-identity)
- [Options: data from nix-secrets](#options-data-from-nix-secrets)
- [Options: capability flags](#options-capability-flags)
- [Options: display](#options-display)
- [Assertions](#assertions)
- [Usage patterns](#usage-patterns)
- [When to add a new option](#when-to-add-a-new-option)

## What hostSpec is

A single `submodule` option declared in `modules/common/host-spec.nix`, imported into the system scope via `hosts/common/core/default.nix` → `modules/common`. On the standalone lane `lib.custom.evalHostSpec` evaluates the same file on its own and returns the attrset for `extraSpecialArgs` — same types, defaults and assertions. `freeformType = attrsOf str` catches only *undeclared* string keys; every option below keeps its declared type.

Values land in two places:

- `hosts/common/core/host-spec.nix` sets `username`, `handle`, `isDarwin` literally and `inherit`s `domain`, `email`, `userFullName`, `sshAllowedSigners`, `networking`, `networkInfo`, `serviceInfo`, `sshClientsInfo` from `inputs.nix-secrets`. The system lanes import it from `core/default.nix`, the standalone lane evaluates it through `evalHostSpec`, so it stays a pure `hostSpec` module with no `imports` and no other options.
- Each `hosts/<lane>/<Host>/default.nix` (darwin, nixos, home) sets `hostName` and per-machine flags.

If the `nix-secrets` input cannot resolve, evaluation dies at the `inherit` with `attribute 'domain' missing`. Fix the input; never comment out the `inherit`, which zeroes every consumer.

**Home-manager does not import this module.** `hostSpec` arrives as a function argument through `extraSpecialArgs`, set in `hosts/common/users/jhl/{darwin,nixos}.nix` on the system lanes and in `mkHomeHost` on the standalone lane. Home modules destructure `{ hostSpec, ... }`. Adding `modules/common` to HM imports creates a second, unpopulated declaration.

## Options: identity

| option | type | default | source at eval | semantics |
|---|---|---|---|---|
| `username` | `str` | none (required) | set in core | Drives `users.users.<u>`, `home-manager.users.<u>`, and the `home` default. Currently `"jhl"`. |
| `hostName` | `str` | none (required) | set per host | `networking.hostName`, `computerName`, `smb.NetBIOSName`, the key for `networkInfo.hosts.<x>`, and the `home/jhl/<hostName>.nix` lookup. Must match the host's directory name under `hosts/<lane>/`. |
| `handle` | `str` | none (required) | set in core | Online handle. Currently `"jhl-hk"`. |
| `userFullName` | `str` | none (required) | `inherit` from nix-secrets | Real name for git `user.name`, GPG uids, mail From. |
| `domain` | `str` | none (required) | `inherit` from nix-secrets | Apex domain for FQDNs. |
| `email` | `attrsOf str` | none (required) | `inherit` from nix-secrets | Project-defined keys; `nix/personal.nix` currently exposes `user`. |
| `home` | `str` | `/home/<u>` on Linux, `/Users/<u>` on Darwin | module default | Evaluated lazily inside the submodule, so the `pkgs.stdenv.isLinux` branch here is safe. |
| `sshAllowedSigners` | `listOf str` | `[ ]` | `inherit` from nix-secrets | One line per element; rendered into `~/.ssh/allowed_signers` for git signature verification. A `listOf`, which is why it needs a declared option rather than the `attrsOf str` freeform escape hatch. |

## Options: data from nix-secrets

Free-shape attrsets kept opaque on purpose, so the public repo never embeds private topology. Read leaves with `.<key> or { }`. Each declares `default = { }` in the module, which is what you get if the `inherit` in core is removed.

| option | type | default | semantics |
|---|---|---|---|
| `networking` | `attrsOf anything` | `{ }` | Generic network knobs: `ports` table, `localDns` (`{ "<domain>" = "<ip>"; }`, read by `hosts/common/core/darwin/local-dns.nix`). |
| `networkInfo` | `attrsOf anything` | `{ }` | Per-host facts: `networkInfo.hosts.<HostName> = { ip4; gateway4; ... }`. Entries may be empty; read with `or { }`. |
| `serviceInfo` | `attrsOf anything` | `{ }` | Per-service endpoint data. Mixes global keys and per-host keys; read with three-level fallback (per-host → global → `{ }`). Currently empty. |
| `sshClientsInfo` | `attrsOf anything` | `{ }` | SSH Host blocks as `programs.ssh.settings` attrs. Rendered into `~/.ssh/config` by `home/jhl/common/core/ssh.nix`. |
| `work` | `attrsOf anything` | `{ }` | Employer bundle. Required non-empty when `isWork = true` (asserted). |
| `persistFolder` | `str` | `""` | impermanence bind-mount root. Only valid empty when impermanence is off (asserted). |

## Options: capability flags

All `bool`. Defaults are tuned so a new host needs the fewest overrides. Flags with no current consumer are declared as a forward contract — do not assume they gate anything today.

| option | default | consumed today? | semantics |
|---|---|---|---|
| `isDarwin` | `false` | **yes** | Set from the `isDarwin` specialArg in core. Read where `pkgs.stdenv.isDarwin` would risk infinite recursion, and by `home/jhl/common/core/default.nix` to pick `./${platform}.nix`. Note `flake.nix` also passes a *separate* top-level `isDarwin` specialArg; they agree but are distinct bindings. |
| `isMobile` | `false` | no | Laptop-shaped host. `true` on jhlsMacBookPro, jhlsMacBookAir, jhlsRogZephyrus. For future power-management / backlight modules. |
| `isMinimal` | `false` | no | Installer/recovery; intended to skip home-manager. |
| `isProduction` | `true` | no | Daily driver vs sandbox; intended to gate noisy debug services. |
| `isServer` | `false` | no | Headless; intended to disable desktop, login manager, audio. `true` on DevEnv. |
| `isWork` | `false` | no | Requires `work` non-empty (asserted). |
| `useYubikey` | `false` | no | Intended for pam-u2f / gpg-agent-ssh / udev. Note the actual YubiKey handling today runs through `sshKeys.primary`, not this flag. |
| `voiceCoding` | `false` | no | talon/cursorless stack. |
| `isAutoStyled` | `false` | no | stylix-driven theming. |
| `useNeovimTerminal` | `false` | no | Embedded nvim terminal instead of a terminal launcher binding. |
| `useWindowManager` | `true` | no | `false` on DevEnv; set `false` on servers / pure-tty hosts. |
| `useAtticCache` | `true` | no | LAN attic substituter. No attic cache exists yet. |
| `hdr` | `false` | no | HDR-capable compositor settings. |
| `loadUserAgeKey` | `false` | no | Load a user-scoped age key in addition to a host key. Currently moot — sops uses the user age key unconditionally (`sops.age.keyFile`). |
| `wifi` | `false` | no | Marker for "host has wifi". |

## Options: display

| option | type | default | semantics |
|---|---|---|---|
| `scaling` | `str` | `"1"` | Floating-point scale factor stored as a **string** (e.g. `"1.25"`) so it can be embedded into config files verbatim without re-quoting. |

## Assertions

Both live in the `config` block of `modules/common/host-spec.nix`:

- `!isWork || work != { }` — "hostSpec.work must be set whenever hostSpec.isWork = true."
- `!isImpermanent || persistFolder != ""` — the `isImpermanent` local is guarded by `config ? "system"` so the file still evaluates in scopes without a `system` namespace.

## Usage patterns

### In a host config

Only the deltas from defaults:

```nix
{
  hostSpec = {
    hostName = "SeandeMac-Studio";
    isMobile = false;
  };
}
```

### In a system module

```nix
{ config, lib, ... }:
let
  hostName = config.hostSpec.hostName;
  netInfo  = config.hostSpec.networkInfo.hosts.${hostName} or { };
in
{
  networking.computerName = hostName;
}
```

Always `or { }` when indexing the secrets-sourced trees.

### In a home-manager module

`hostSpec` is a function argument here, not `config`. Example: `recipes.md` Recipe 5a (`programs.git`), which mixes `hostSpec` from the argument with `config.sshKeys` from the HM option declared in `modules/home/ssh-keys.nix`.

## When to add a new option

Add to `hostSpec` only when (a) at least two modules read it and (b) it is genuine cross-host metadata — identity, topology, or a coarse capability tier — rather than a per-feature toggle.

A switch that exactly one module reads belongs to that module as `options.<module>.<x>`, so ownership stays next to the consumer. `sshKeys.primary` (`modules/home/ssh-keys.nix`), `darwinYubikey.enable`, and `darwinWallpaper` are all deliberately *not* in hostSpec for this reason.

When the new field is a free-shape tree from secrets, keep the type `attrsOf anything` and document the expected leaf shape in the option `description` so consumers can defend with `or { }`.
