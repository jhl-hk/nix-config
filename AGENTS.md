# Repository Guidelines

## Project Structure & Module Organization
This repo is a Nix flake for multi-host nix-darwin/NixOS configs.
- `flake.nix` and `flake.lock`: entry point and locked inputs.
- `hosts/`: host-level system modules.
  - `common/`: shared core and Darwin-specific modules.
  - `optional/`: opt-in modules imported by specific hosts.
  - `darwin/<hostname>/`: per-host macOS configs (e.g., `hosts/darwin/jhlsMacBookAir`).
- `home/`: Home Manager modules and user programs.
  - `default.nix`: main Home Manager entry.
  - `programs/` and `shell/`: program- and shell-specific modules.
- `assets/`: images and other static files referenced by configs.

## Build, Test, and Development Commands
Use `just` recipes from `justfile`:
- `just switch`: build and switch the current host (`darwin-rebuild switch --flake .#<hostname>`).
- `just build`: build without switching (safe dry run).
- `just check`: run `nix flake check --all-systems`.
- `just update`: update flake inputs (`nix flake update`).
- `just clean`: garbage-collect old generations (`nix-collect-garbage -d`) and run `mo clean`.

Manual examples:
```bash
darwin-rebuild switch --flake .#jhlsMacBookAir
nix flake check --all-systems
```

## Coding Style & Naming Conventions
- Nix files use 2-space indentation and braces aligned as in existing modules.
- Keep host names consistent with existing patterns (e.g., `jhlsMacBookAir`) and place host modules in `hosts/darwin/<hostname>/default.nix`.
- Prefer small, composable modules in `hosts/common/` or `hosts/optional/` over large monolithic files.
- Follow existing comment style; avoid introducing non-ASCII unless already in use in the file.

## Testing Guidelines
There are no dedicated unit tests. Use:
- `just check` for flake validation.
- `just build` or `darwin-rebuild build` to ensure configs evaluate before switching.

## Commit & Pull Request Guidelines
Commit history favors short, imperative summaries and sometimes a type prefix:
- Examples: `fix: update darwin`, `Feat: add ssh`, `Update ssh.nix`.
For new work, keep messages concise and consistent (choose `fix:`, `feat:`, `add`, or `update`).

For PRs, include:
- A short description of what changed and why.
- The host(s) affected and the command used to validate (`just check`, `just build`, etc.).
- Screenshots only if UI-facing assets in `assets/` change.

## Security & Configuration Tips
- Avoid committing secrets; use external secret management if needed.
- Test on one host before rolling out to others.
