# nix-config

jhl's nix-darwin + home-manager flake, currently managing three Macs. The NixOS skeleton is in place but no machine uses it yet.

Private data lives in the sibling [`../nix-secrets`](https://github.com/jhl-hk/nix-secrets) (private) and is pulled in as a flake input.

## Layout

```
.
├── flake.nix              # host auto-discovery, overlays, packages, checks, devShells
├── lib/                   # lib.custom: relativeToRoot / scanPaths
├── modules/               # reusable option-providing modules, all auto-imported by scanPaths
│   ├── common/            #   shared across NixOS/Darwin/HM -- host-spec.nix lives here
│   ├── home/              #   home-manager scope
│   └── hosts/{common,nixos,darwin}/
├── overlays/              # additions / customLib / modifications / unstable
├── pkgs/common/           # home-grown packages, auto-discovered by packagesFromDirectoryRecursive
├── hosts/
│   ├── common/
│   │   ├── core/          # what every machine gets, including the hostSpec population point
│   │   ├── users/jhl/     # system-level user + home-manager wiring
│   │   └── optional/      # ★ never auto-imported; a host names what it wants
│   ├── darwin/<HostName>/ # one directory per machine, auto-discovered
│   └── nixos/             # empty skeleton
└── home/jhl/
    ├── common/core/       # the baseline wanted everywhere
    ├── common/optional/   # picked per machine
    └── <HostName>.nix     # each machine's order ticket
```

## Three composition lanes + one data bus

**Hosts** — drop a directory in `hosts/darwin/<Name>/` and that is a new machine; `flake.nix` discovers it with `readDir`. Host files are thin: set `hostSpec.hostName`, then pick what you need from `hosts/common/optional/`.

**Home** — each `(user, machine)` pair maps to `home/jhl/<HostName>.nix`, which imports `common/core` plus a selection of `common/optional`.

**Modules** — files under `modules/**` are auto-imported by `lib.custom.scanPaths`. They only provide `options` and enable nothing. Enabling is the host's job (`<name>.enable = true`).

**The data bus** — `modules/common/host-spec.nix` defines the `hostSpec` option tree, and `hosts/common/core/default.nix` populates it with a single `inherit (inputs.nix-secrets) ...`. After that every module reads `config.hostSpec.<x>` and must **never** touch `inputs.nix-secrets` directly.

### The single most important rule

`modules/**` **is** auto-imported; `hosts/common/optional/**` **is not**. The former defines capabilities, the latter describes one machine's choices — so opening a host file shows you everything that machine runs.

## Common commands

```bash
just                # list every recipe
just rebuild        # rebuild and switch this machine (runs update-nix-secrets before and check-sops after)
just build          # build without switching
just check          # nix flake check --all-systems; really builds every machine
just diff           # git diff, excluding flake.lock
just update         # update flake inputs + brew
just fmt            # format with alejandra
just check-beta     # report whether this machine is on a macOS seed build
just clean          # clean up old generations

nix develop         # dev shell: sops / age / ssh-to-age / just / gum / alejandra / deadnix
```

Secrets:

```bash
just sops-edit shared    # edit ../nix-secrets/secrets/shared.yaml (creates the dir, checks the age key)
just rekey               # after editing .sops.yaml, re-encrypt every ciphertext for the current recipients
just update-nix-secrets  # pull nix-secrets and re-lock it
just check-sops          # assert every secret this machine declares landed in /run/secrets (runs after rebuild)
just verify-sops         # end-to-end canary self-check, see below
```

**There is no CI.** No `.github/`, no GitHub Actions. `just check` is the gate before pushing, run locally.

### Verifying the sops pipeline

After changing an age key, the `.sops.yaml` recipients, or upgrading macOS, a one-off canary can verify the whole path end to end. The canary module is deleted once verified; restore it from git history:

```bash
p=hosts/common/optional/darwin/sops-canary.nix
git show "$(git rev-list -n1 HEAD -- "$p")^:$p" > "$p"
```

(`rev-list -n1` finds the last commit that touched the file — the one that deleted it — and `^` takes its parent. Plain `git show HEAD:$p` does not work, because after the deletion HEAD no longer has the file.)

Then follow the three steps at the top of that file (create the ciphertext → import → rebuild). `just verify-sops` checks four things: the raw secret's value, whether the `sops.templates` placeholder was really substituted, the target's permissions, and a `launchctl kickstart` re-run proving the **boot path** works too. When done, remove the import, the canary in `shared.yaml`, and the module itself.

`just verify-sops` checks its preconditions first and tells you exactly which step is missing rather than dumping a wall of red crosses at you.

## Where to add things

| What you want to add | Where it goes |
|---|---|
| A system package every machine needs | `environment.systemPackages` in `hosts/common/core/default.nix` |
| A feature some machines want, with no parameters | `hosts/common/optional/darwin/<name>.nix`, then name it in the host's `imports` |
| A feature with parameters and an `enable` switch | `modules/hosts/darwin/<name>/default.nix` (auto-imported) |
| A Homebrew brew/cask/masApp | `hosts/common/core/darwin/apps.nix` (fleet-wide) or an optional file (some machines) |
| A dotfile wanted everywhere | `home/jhl/common/core/<name>.nix` + add it to the imports in the sibling `default.nix` |
| A dotfile that only holds on macOS | `home/jhl/common/core/darwin/<name>.nix` |
| A dotfile switched per machine | `home/jhl/common/optional/<category>/<name>.nix`, named in `home/jhl/<Host>.nix` |
| A package not in nixpkgs | `pkgs/common/<name>/package.nix` (auto-discovered) |
| An override of a nixpkgs package | `modifications` in `overlays/default.nix`; for a newer version prefer `pkgs.unstable.<x>` |

Full templates and edge cases are in `claude/skills/nix-config/references/recipes.md`.

## Traps you have to know about

- **`system.stateVersion` has a different type per platform**: nix-darwin wants an integer (`6`), NixOS wants a string (`"25.05"`). Mixing them up is a type error at evaluation time. It pins migration logic, not the running version — do not touch it without reading the release notes.
- **`lib.custom.relativeToRoot` takes a string, not a path literal**. `relativeToRoot "hosts/common/core"` is correct; `relativeToRoot ./hosts/common/core` is not.
- **`environment.systemPath` must use `lib.mkOrder 1100`**. nix-darwin defines the nix paths at default order 1000 and the `/usr/bin` set at 1200; a plain definition drifts with module order, which can put Homebrew's paths ahead of nix or behind `/usr/bin`.
- **Never pass `lib` in home-manager's `extraSpecialArgs`**. It clobbers HM's own lib, `lib.hm` disappears, and a pile of modules break. `lib.custom` reaches HM through the `customLib` layer in overlays, which attaches it to `pkgs.lib`.
- **sops's two delivery paths differ in visibility**. On `switch` it goes through `postActivation` (`activate` runs with `set -e`, so a decryption failure **aborts the switch with an error**); at boot it goes through `launchd.daemons.sops-install-secrets`, whose output only reaches the launchd log.
- **What `sops.templates.<x>.path` lands is a symlink**, pointing at `/run/secrets/rendered/<name>`, while `/run/secrets` is itself `→ /run/secrets.d/N` (generation-numbered, switched atomically at activation). Three consequences: `owner`/`mode` apply to the **target** (use `stat -L` to check permissions); `/run` is volatile and rebuilt by launchd after a reboot, so until that finishes it is a dangling link; and **any command that writes to that path** (`npm login`, `npm config set`) writes through the symlink into `/run/secrets/rendered/`, where the next activation wipes it — to change a value, change the source YAML.
- **The order of adding a secret cannot be reversed**: create and push the ciphertext in `nix-secrets` first, then import the consuming module on the host. The other way round fails during evaluation (`opening file ... No such file or directory`), because `validateSopsFiles` checks for the file at evaluation time.
- **Removing the last secret leaves orphans.** Once both `sops.secrets` and `sops.templates` are empty, the sops-nix module disappears from the system entirely — along with its cleanup code. Three things are left unattended: the `~/<template path>` symlink, `/run/secrets` → `/run/secrets.d/N`, and **`/run/secrets.d/age-keys.txt` (the cleartext copy of the age private key that sops-nix made)**. To clean up:

  ```bash
  rm ~/<template path>
  sudo rm -rf /run/secrets /run/secrets.d
  sudo hdiutil detach /dev/diskN
  sudo rmdir /run/secrets.d
  ```

  `/run/secrets.d` is a 64 MiB **HFS RAM disk** (`mount | grep secrets.d` shows the device number), so `rm -rf` empties it but cannot remove the mount point itself, reporting `Resource busy` — deleting the contents is enough for safety, the rest just reclaims memory. macOS clears `/run` on reboot, but do not rely on that.
- **`onActivation.cleanup = "zap"`**: any Homebrew package not declared in `apps.nix` is uninstalled on the next switch. Anything from a manual `brew install` is temporary.
- **Always push changes to nix-secrets.** It is a locked remote input, so local edits are invisible to the flake. `just rebuild` runs `update-nix-secrets` for you, but pushing is on you.

## References

- Design lineage: [EmergentMind/nix-config](https://github.com/EmergentMind/nix-config)
- [nix-darwin manual](https://daiderd.com/nix-darwin/manual/index.html) · [home-manager manual](https://nix-community.github.io/home-manager/) · [NixOS Options](https://search.nixos.org/options)
