# nix-secrets Reference

The sibling flake at `/Users/jhl/Documents/nix-src/nix-secrets` (GitHub `jhl-hk/nix-secrets`, private). The single home for secret-handling rules, sops consumption and failure visibility.

## Contents

- [Overview](#overview)
- [nix/ schemas](#nix-schemas)
- [agents/AGENTS.md](#agentsagentsmd)
- [.sops.yaml](#sopsyaml)
- [secrets/shared.yaml](#secretssharedyaml)
- [Consuming secrets: system scope](#consuming-secrets-system-scope)
- [Consuming secrets: home-manager scope](#consuming-secrets-home-manager-scope)
- [Failure visibility](#failure-visibility)
- [What agents must not do](#what-agents-must-not-do)

## Overview

| Path | Content | Consumed by |
|---|---|---|
| `nix/*.nix` | Plaintext attrsets (identity, network, services, SSH clients); `flake.nix` merges them with `foldl' recursiveUpdate { }` | `inherit (inputs.nix-secrets) ...` in `hosts/common/core/host-spec.nix` → `hostSpec` (`hostspec.md`) |
| `agents/AGENTS.md` | Global agent instructions | `home/jhl/common/core/agent-instructions.nix` |
| `secrets/*.yaml` | sops-encrypted YAML | `sops.secrets` / `sops.templates` |
| `.sops.yaml` | recipients | `sops`, `just rekey` |

```nix
nix-secrets.url = "git+ssh://git@github.com/jhl-hk/nix-secrets.git?ref=main&shallow=1";
```

**Locked remote input.** Local edits are invisible until committed, pushed and re-locked. `just update-nix-secrets` (run by every `just rebuild`) fetches, rebases and re-locks; the push is the user's.

## nix/ schemas

### nix/personal.nix

```nix
{
  domain       = "jhl.hk";
  userFullName = "jhl-hk";
  email = { user = "ja@jhl.hk"; };
  sshAllowedSigners = [ "ja@jhl.hk sk-ssh-ed25519@openssh.com AAAA..." ];
}
```

`email` keys are project-defined; only `user` exists. `sshAllowedSigners` holds public keys, rendered to `~/.ssh/allowed_signers` by `home/jhl/common/core/default.nix` (`lib.concatLines`).

### nix/network.nix

```nix
{
  networkInfo.hosts.<HostName> = {
    ip4       = "...";   # all fields optional
    gateway4  = "...";
    dns       = [ ];
    mac       = "...";
    interface = "en0";
  };
  networking.ports    = { tcp = { ssh = 22; }; udp = { }; };
  networking.localDns = { "<domain>" = "<ip>"; };   # hosts/common/core/darwin/local-dns.nix
}
```

Read: `config.hostSpec.networkInfo.hosts.${config.hostSpec.hostName} or { }`.

### nix/services.nix

`serviceInfo = { }` today. Intended shape mixes global and per-host keys:

```nix
serviceInfo = {
  <service> = { ... };              # global
  <HostName>.<service> = { ... };   # per-host
};
```

```nix
cfg = config.hostSpec.serviceInfo.${hostName}.foo
   or config.hostSpec.serviceInfo.foo
   or { };
```

### nix/ssh-clients.nix

```nix
sshClientsInfo.<HostAlias> = {
  HostName = "10.1.10.8";
  User = "<login>";
  SetEnv = { TERM = "xterm-256color"; };  # optional
};
```

Merged into `programs.ssh.settings` by `home/jhl/common/core/ssh.nix`; the `"*"` block renders after it.

## agents/AGENTS.md

Linked read-only to `~/.omp/agent/AGENTS.md` by `home/jhl/common/core/agent-instructions.nix`. Edit in `../nix-secrets`, push, `just update-nix-secrets`, rebuild. User-edited file; agents propose changes.

## .sops.yaml

One anchor per host under `keys.users`; one creation rule (`secrets/[^/]+\.yaml$`) lists all six:

| Anchor | Key |
|---|---|
| `&jhlsMacBookPro` | `age1hj2df6…` (same key as jhlsMacBookAir) |
| `&jhlsMacBookAir` | `age1hj2df6…` |
| `&jhlsRogZephyrus` | own key |
| `&jhlsTokyoDesktop` | own key |
| `&SeandeMac-Studio` | own key |
| `&DevEnv` | own key |

- Each machine decrypts with the user age key at `~/.config/sops/age/keys.txt`; no host SSH keys are used.
- Every file has the same recipients: `shared.yaml` vs `<HostName>.yaml` is organisation, not a permission boundary.
- A new machine needs its public key (`just age-key <path>` prints it) added as an anchor and to the rule, then `just rekey` — all by the user.
- A YubiKey recipient needs `age-plugin-yubikey` plus a new anchor, then `just rekey`.

## secrets/shared.yaml

The only ciphertext file. Top-level keys:

| Key | Consumers |
|---|---|
| `ssh` | `hosts/common/core/darwin/ssh-shared-key.nix`, `sops/standalone.nix` (`ssh/id_shared`) |
| `tea` | `hosts/common/core/darwin/forgejo.nix`, `hosts/common/optional/nixos/forgejo.nix`, `sops/standalone.nix` (`tea/token`) |
| `yubikey` | `modules/hosts/darwin/yubikey` |
| `cloudflare` | `hosts/common/optional/darwin/cloudflare.nix`, `sops/standalone.nix` |
| `llm`, `llm_api` | `hosts/common/optional/common/llm.nix`, `sops/standalone.nix` (`llm` only), `just llm-models` |
| `wakatime` | `hosts/common/optional/darwin/wakatime.nix`, `sops/standalone.nix` (`wakatime/api_key`) |
| `omni` | `modules/hosts/darwin/omni`, `home/jhl/common/optional/k8s/omni.nix` |
| `rd_llm`, `openai`, `openclaw` | no consumer in nix-config |

Key paths are `<area>/<name>` (e.g. `llm/api_key`, `wakatime/api_key`). `hosts/common/optional/darwin/npmrc.nix` declares `npm/jianyuelab_token`, which does not exist; no host imports it.

## Consuming secrets: system scope

Macs and NixOS. `hosts/common/core/sops.nix` imports `sops-nix.darwinModules.sops` or `nixosModules.sops` (chosen by the `isDarwin` specialArg) and sets `sops.age.keyFile = "${hostSpec.home}/.config/sops/age/keys.txt"`. It declares no secrets.

```nix
{ config, inputs, ... }:
{
  sops.secrets."<area>/<name>" = {
    sopsFile = "${inputs.nix-secrets}/secrets/shared.yaml";
    owner = config.hostSpec.username;
    mode  = "0400";
  };

  services.something.tokenFile = config.sops.secrets."<area>/<name>".path;
}
```

Secret embedded in a larger file → template (`.path` gives only the raw value):

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

- **Paths are symlinks.** A template `path` → `/run/secrets/rendered/<name>`; `/run/secrets` → `/run/secrets.d/N` (swapped atomically). `owner`/`mode` apply to the target (`stat -L`). Writes through the link (`npm login`, `npm config set`, `git config -f`) are wiped next activation; change the YAML.
- **`/run` is volatile.** Darwin's launchd daemon re-creates secrets after boot; until then links dangle.
- **Order:** the ciphertext must be pushed and locked before a host imports the consumer; `validateSopsFiles` checks at evaluation time (`opening file ... No such file or directory`).
- **Assertion guard:** `lib.hasInfix "<key>:" (builtins.readFile sopsFile)` turns an unfilled key into an evaluation error naming it (sops leaves key names in cleartext). Pattern: `modules/hosts/darwin/omni/default.nix`.
- **Key file first:** `~/.config/sops/age/keys.txt` must exist before the first rebuild that declares a secret.
- **System and home trees cannot reference each other:** `/run/secrets/<path>` defaults in home modules (`llm.apiKeyFile`, `wakatime.apiKeyFile`, `cloudflare.apiTokenFile`) are kept in step with the system `sops.secrets` names by hand.

### Removing the last secret orphans sops-nix artifacts (Darwin)

With `sops.secrets` and `sops.templates` both empty, sops-nix drops out of the system, cleanup code included. Left behind:

- `~/<template path>` symlinks
- `/run/secrets` → `/run/secrets.d/N`
- `/run/secrets.d/age-keys.txt` — a plaintext copy of the age private key, root `0600`

```bash
rm ~/<template path>
sudo rm -rf /run/secrets /run/secrets.d      # removes contents incl. age-keys.txt
sudo hdiutil detach /dev/diskN               # N from: mount | grep secrets.d
sudo rmdir /run/secrets.d
```

`/run/secrets.d` is a 64 MiB HFS RAM disk, so `rm -rf` ends with `Resource busy` on the mount point; contents are gone at that point. Removing one secret among several is unaffected.

## Consuming secrets: home-manager scope

Standalone hosts only, through `home/jhl/common/optional/sops/standalone.nix` (Recipe 8b in `recipes.md`):

| Aspect | Value |
|---|---|
| Module | `inputs.sops-nix.homeManagerModules.sops` |
| Key | `~/.config/sops/age/keys.txt` |
| `defaultSopsFile` | `${inputs.nix-secrets}/secrets/shared.yaml` |
| Decrypted to | `$XDG_RUNTIME_DIR`, linked under `~/.config/sops-nix/secrets/` |
| Declared | `llm/api_key`, `cloudflare/api_token`, `wakatime/api_key`, `tea/token`, `ssh/id_shared` (→ `~/.ssh/id_shared`, 0400) |
| Consumers | repointed with `lib.mkForce` from `/run/secrets/...` |
| Service | systemd user `sops-nix.service`; dependents use `After`/`Requires` on it |

## Failure visibility

| Path | Lane | When | Visibility |
|---|---|---|---|
| `system.activationScripts.postActivation` | darwin | switch | Loud: inlined into `activate` under `set -e`; a decryption failure aborts the switch. |
| `launchd.daemons.sops-install-secrets` (`RunAtLoad`) | darwin | boot | Quiet: launchd log only. |
| sops-nix NixOS module | nixos | switch / boot | Not covered by `check-sops`; check `/run/secrets` on the host. |
| `sops-nix.service` (user) | standalone | login / switch | `systemctl --user status sops-nix`; not covered by `check-sops`. |

- `just check-sops` (rebuild-post, Darwin only) asserts every declared secret is non-empty under `/run/secrets`; skips when none are declared.
- `just verify-sops` (Darwin only) runs the canary end to end, boot path included; the canary module must be restored from git history first (`commands.md` § Secrets).

## What agents must not do

- Run `sops` in any form, `just rekey`, or `just age-key`.
- Write or modify anything under `secrets/`, or edit `.sops.yaml`.
- Invent age keys.
- Commit or push in `../nix-secrets`.
- Read decrypted values from `/run/secrets/*` or `~/.config/sops-nix/secrets/*`.
- Reference `inputs.nix-secrets.<x>` in modules; go through `hostSpec`. Exceptions are store paths: `"${inputs.nix-secrets}/secrets/<file>.yaml"` as `sopsFile`, `"${inputs.nix-secrets}/agents/AGENTS.md"` as a source.

Agents may: describe a YAML file's shape, name the exact key path and file, edit `nix/*.nix` plaintext schemas, and tell the user which `just` recipe to run.

New secret:

1. Add `sops.secrets."<path>"` (system or `sops/standalone.nix`) and the `hasInfix` assertion.
2. Reference `config.sops.secrets."<path>".path` or a template.
3. Tell the user the YAML key and file, plus `just sops-edit shared` → commit + push in `../nix-secrets` → `just update-nix-secrets`. Stop.
