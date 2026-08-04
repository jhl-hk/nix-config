# nix-secrets Reference

Orientation to the sibling flake at `/Users/jhl/Documents/nix-src/nix-secrets` (GitHub: `jhl-hk/nix-secrets`, private). Agents query this data when wiring modules; they do not run `sops` or write encrypted files.

## Contents

- [Overview](#overview)
- [nix/ schemas](#nix-schemas)
- [.sops.yaml](#sopsyaml)
- [secrets/](#secrets)
- [Consuming secrets in modules](#consuming-secrets-in-modules)
- [What agents must not do](#what-agents-must-not-do)

## Overview

A standalone flake split in two halves:

- **`nix/`** — plaintext attrsets ("soft" data: identity, network layout, service endpoints, SSH client config). `flake.nix` merges every `.nix` file under `nix/` with `foldl' recursiveUpdate { }`, so adding a schema is just adding a file.
- **`secrets/`** — sops-encrypted YAML ("hard" data: tokens, passwords, private keys).

`nix-config` pulls it in as the `nix-secrets` flake input:

```nix
nix-secrets.url = "git+ssh://git@github.com/jhl-hk/nix-secrets.git?ref=main&shallow=1";
```

The seam is `hosts/common/core/default.nix`:

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

Modules read soft data through `config.hostSpec.<x>` (or the `hostSpec` argument in home scope). A schema not re-exported through `hostSpec` — currently only `sshClientsInfo` — would be read as `inputs.nix-secrets.sshClientsInfo or { }`, but nothing consumes it yet.

**It is a locked remote input.** Local edits in `../nix-secrets` are invisible to `.#<host>` evaluation until committed, pushed, and re-locked. `just update-nix-secrets` does the fetch/rebase/re-lock and runs automatically before every `just rebuild`; the push is manual.

## nix/ schemas

### nix/personal.nix

```nix
{
  domain       = "jhl.hk";
  userFullName = "jhl-hk";     # git user.name — kept as the handle, change freely
  email = { user = "ja@jhl.hk"; };
  sshAllowedSigners = [ "ja@jhl.hk sk-ssh-ed25519@openssh.com AAAA..." ];
}
```

`email` keys are project-defined; only `user` exists today. Adding `gitHub` or `notifier` is a one-line change plus whatever consumes it.

`sshAllowedSigners` holds **public** keys — it lives in the private repo because it's identity, not because it's secret. Rendered into `~/.ssh/allowed_signers` by `home/jhl/common/core/default.nix` via `lib.concatLines`.

### nix/network.nix

```nix
{
  networkInfo.hosts.<HostName> = {
    ip4       = "...";   # optional
    gateway4  = "...";   # optional
    dns       = [ ];     # optional
    mac       = "...";   # optional
    interface = "en0";   # optional
  };
  networking.ports = { tcp = { ssh = 22; }; udp = { }; };
}
```

All three Macs are DHCP, so their entries are present but empty. The keys exist so `networkInfo.hosts.${hostName}` indexing doesn't throw.

Read pattern: `config.hostSpec.networkInfo.hosts.${config.hostSpec.hostName} or { }`.

### nix/services.nix

Currently `serviceInfo = { }`. The intended shape mixes two key kinds under one attrset — the most error-prone part of the schema:

```nix
serviceInfo = {
  <service> = { ... };              # global — any host may opt in
  <HostName>.<service> = { ... };   # per-host — only that machine
};
```

Canonical read, per-host wins then global then empty:

```nix
let
  hostName = config.hostSpec.hostName;
  cfg = config.hostSpec.serviceInfo.${hostName}.foo
     or config.hostSpec.serviceInfo.foo
     or { };
in ...
```

### nix/ssh-clients.nix

Currently `sshClientsInfo = { }`. Each value is a raw multi-line SSH config block, not structured attrs:

```nix
sshClientsInfo.<HostAlias> = ''
  HostName 10.1.10.8
  User <login>
  ForwardAgent yes
'';
```

Nothing renders these yet. Wiring them up means a new `modules/home/ssh-clients.nix` that writes `~/.ssh/config.d/hosts` and exposes an opt-in list.

## .sops.yaml

**One anchor pool only.** macOS does not derive a host key from `/etc/ssh/ssh_host_ed25519_key` here — every machine decrypts with the same user age key at `~/.config/sops/age/keys.txt`. So there is no `keys.hosts` section:

```yaml
keys:
  users:
    - &jhl age1hj2df6jv8q830960pjjg9gmg3kfgv74nx3sepv87hmgq78ue4qfsrmqxep

creation_rules:
  - path_regex: secrets/[^/]+\.yaml$
    key_groups:
      - age:
          - *jhl
```

Consequences worth stating plainly:

- Every file under `secrets/` has the same recipient list, so **`shared.yaml` vs `<HostName>.yaml` is organisation, not a permission boundary.** Splitting per host buys tidiness, not isolation.
- **Losing that age key means every secret is permanently unrecoverable.** There is no host-key fallback.
- Adding a YubiKey recipient requires `age-plugin-yubikey` plus a new anchor under `users`, then `just rekey`.

## secrets/

No encrypted files exist yet. The first intended one is `secrets/shared.yaml` holding:

```yaml
npm:
    jianyuelab_token: ghp_...
```

consumed by `hosts/common/optional/darwin/npmrc.nix` (not imported by any host until the user creates the secret).

Naming convention for future keys: `<area>/<name>`, e.g. `npm/jianyuelab_token`, `keys/ssh/backup`, `api/wakatime`.

## Consuming secrets in modules

`hosts/common/core/sops.nix` provides plumbing only — the sops-nix module and `sops.age.keyFile`. It declares no secrets, so a machine never fails to evaluate over an unfilled YAML key.

```nix
{ config, inputs, ... }:
{
  sops.secrets."<area>/<name>" = {
    sopsFile = "${inputs.nix-secrets}/secrets/shared.yaml";
    owner = config.hostSpec.username;
    mode  = "0400";
  };

  # Reference the decrypted path:
  services.something.tokenFile = config.sops.secrets."<area>/<name>".path;
}
```

When the secret is one substring of a larger file format, use a template — `.path` only gives the raw value:

```nix
sops.templates."name" = {
  content = ''
    token=${config.sops.placeholder."<area>/<name>"}
  '';
  owner = config.hostSpec.username;
  mode  = "0600";
  path  = "${config.hostSpec.home}/.config/app/config";
};
```

### Failure visibility

`sops-install-secrets` runs on two paths, and they are **not** equally visible:

| Path | When | Visibility |
|---|---|---|
| `system.activationScripts.postActivation` | `darwin-rebuild switch` | **Loud.** `/run/current-system/activate` starts with `set -e` and the install script is inlined into it, so a decryption failure aborts the switch with an error. |
| `launchd.daemons.sops-install-secrets` (`RunAtLoad = true`) | boot | Quiet — output goes to launchd logs, not a terminal. `/run` is volatile, so this is what re-creates secrets after a reboot. |

So a failure at switch time will not be missed. What *can* be missed is a boot-time failure, and a config that declares a secret which silently never materialises.

`just check-sops` (run automatically by `rebuild-post`) reads the host's declared `sops.secrets` attribute names and asserts each `/run/secrets/<name>` exists and is non-empty; it exits 0 with a "skipped" message when nothing is declared, so it never fakes a pass.

For end-to-end proof of a new pipeline, use the canary: `hosts/common/optional/darwin/sops-canary.nix` plus `just verify-sops`. It exercises both `sops.secrets` (raw) and `sops.templates` (placeholder substitution), checks permissions, and kickstarts the launchd daemon to prove the boot path too.

Also: `~/.config/sops/age/keys.txt` must exist **before** the first rebuild that declares a secret, or activation fails.

## What agents must not do

- Do not run `sops` in any form. The age key lives only on the user's machine.
- Do not write or modify any file under `secrets/`. Committing plaintext there silently breaks decryption for everyone.
- Do not edit `.sops.yaml` to add or rotate anchors — that's a user-side trust decision.
- Do not invent age keys.
- Do not run `just rekey`; it re-encrypts every YAML and must be invoked by the user after they touch `.sops.yaml`.
- Do not commit or push in `../nix-secrets`.
- Do not read decrypted values from `/run/secrets/*`.
- Do not introduce direct `inputs.nix-secrets.<x>` references in modules — go through `config.hostSpec` (or the `hostSpec` argument in home scope). The one legitimate exception is `"${inputs.nix-secrets}/secrets/<file>.yaml"` as a `sopsFile` path, which is a store path, not data.

What agents *may* do: describe the shape of a YAML file, name the exact key path and file the user should open, point at the `inherit (inputs.nix-secrets) ...` line, edit files under `nix/` (plaintext schemas), and tell the user which `just` recipe to run themselves.

When a recipe needs a new secret:

1. Add the `sops.secrets."<path>"` block to the consuming module with the correct `sopsFile`.
2. Reference `config.sops.secrets."<path>".path` or a `sops.templates` entry.
3. Tell the user the exact YAML key and file, then wait — do not rebuild on their behalf.
