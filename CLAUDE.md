# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Multi-host, multi-user NixOS and nix-darwin configuration using flakes. Based on EmergentMind/nix-config principles with a modular, scalable architecture using core + optional pattern.

## Common Commands

### Building and Switching

```bash
# Build and switch to new configuration (auto-detects hostname)
make switch

# Build without switching (test before applying)
make build

# Or manually specify hostname:
darwin-rebuild switch --flake .#jhlsMacBookAir
darwin-rebuild build --flake .#jhlsMacBookPro
```

### Updating and Maintenance

```bash
# Update all flake inputs
make update

# Check flake for errors
make check

# Clean old generations (7+ days old)
make clean

# Remove all old generations
make clean-all

# Format nix files
make fmt
```

### Debugging

```bash
# Show what would change
make diff

# Show system generations history
make history

# Show flake outputs
make show

# Show system info
make info
```

## Architecture

### Directory Structure

- **`flake.nix`**: Main entry point defining all system configurations
- **`hosts/`**: Host-specific configurations
  - `common/core/`: Required configs for ALL hosts (Nix settings, core packages)
  - `common/darwin/`: Common macOS-specific configs (system defaults, Homebrew)
  - `common/optional/`: Optional modules hosts can import
  - `darwin/<hostname>/`: macOS host definitions
  - `nixos/<hostname>/`: NixOS host definitions (future)
- **`users/<username>/`**: System-level user configurations (user accounts, shell, trusted users)
- **`home/<username>/`**: Home Manager user environments (dotfiles, user packages, programs)
  - `common/optional/`: Optional home modules
  - `<username>/programs/`: Program-specific configs (git, zsh, etc.)
  - `<username>/shell/`: Shell configurations

### Configuration Flow

1. **`flake.nix`** calls `mkDarwin` or `mkNixOS` helper functions
2. Helpers automatically import in order:
   - `hosts/common/core/` (always loaded)
   - `hosts/common/darwin/` or NixOS equivalent
   - Host-specific config from `hosts/darwin/<hostname>/`
   - User config from `users/<username>/`
   - Home Manager with `home/<username>/`
3. Optional modules are imported explicitly in host configs

### Helper Functions in flake.nix

**`mkDarwin`**: Creates macOS configurations
- Parameters: `hostname`, `system` (default: aarch64-darwin), `username`, `modules` (optional)
- Auto-wires Home Manager integration

**`mkNixOS`**: Creates NixOS configurations
- Parameters: `hostname`, `system` (default: x86_64-linux), `username`, `modules` (optional)
- Auto-wires Home Manager integration

### Special Args Available

All modules receive these special args:
- `inputs`: Flake inputs (nixpkgs, darwin, home-manager)
- `outputs`: Flake outputs (self reference)
- `hostname`: Current host name
- `username`: Current user name
- `pkgs`: Nixpkgs package set

## Adding New Hosts

### macOS Host

1. Copy template: `cp -r hosts/darwin/_template hosts/darwin/newhostname`
2. Edit `hosts/darwin/newhostname/default.nix`:
   - Set `networking.hostName`
   - Import any optional modules from `../../common/optional/`
3. Add to `flake.nix` in `darwinConfigurations`:
   ```nix
   newhostname = mkDarwin {
     hostname = "newhostname";
     system = "aarch64-darwin";  # or x86_64-darwin
     username = "jhl";
   };
   ```
4. Build: `darwin-rebuild switch --flake .#newhostname`

### NixOS Host

1. Generate hardware config on target: `nixos-generate-config --show-hardware-config`
2. Copy template: `cp -r hosts/nixos/_template hosts/nixos/newhostname`
3. Move hardware config to `hosts/nixos/newhostname/hardware-configuration.nix`
4. Edit `hosts/nixos/newhostname/default.nix`
5. Add to `flake.nix` in `nixosConfigurations`
6. Build: `sudo nixos-rebuild switch --flake .#newhostname`

## Adding New Users

1. Copy templates:
   ```bash
   cp -r users/_template users/newuser
   cp -r home/_template home/newuser
   ```
2. Edit `users/newuser/default.nix`:
   - Set `users.users.newuser.home` (path differs: `/Users/` on macOS, `/home/` on Linux)
   - Set `system.primaryUser` (Darwin only)
   - Add to `nix.settings.trusted-users`
3. Edit `home/newuser/default.nix`:
   - Update `home.username` and `home.homeDirectory`
   - Customize packages and settings
4. Assign to host in `flake.nix` by changing `username` parameter
5. Rebuild system

## Key Configuration Files

### Homebrew Packages

Edit `hosts/common/darwin/homebrew.nix`:
- `brews`: CLI tools from Homebrew
- `casks`: GUI applications
- `masApps`: Mac App Store apps (requires `mas signin`)
- `onActivation.cleanup = "zap"`: Removes undeclared packages

### System Defaults

Edit `hosts/common/darwin/system-defaults.nix`:
- macOS preferences (Dock, Finder, trackpad, etc.)
- All options: https://daiderd.com/nix-darwin/manual/index.html#sec-options

### Nix Settings

Edit `hosts/common/core/nix-settings.nix`:
- Experimental features (flakes, nix-command)
- Trusted users
- Substituters and cache keys

## Home Manager Configuration

User-specific configs in `home/<username>/`:
- **Programs**: `programs/<program>.nix` - Individual program configs (git, zsh, etc.)
- **Shell**: `shell/<shell>.nix` - Shell configurations and prompts
- Import structure in `home/<username>/default.nix`

Common patterns:
```nix
# Add user packages
home.packages = with pkgs; [ neovim ripgrep ];

# Configure program
programs.git = {
  enable = true;
  userName = "name";
  userEmail = "email";
};

# Set environment variables
home.sessionVariables = {
  EDITOR = "vim";
};
```

## Important Notes

### Nixpkgs Versions

- Uses `nixpkgs-unstable` for most packages (latest)
- Uses `nixpkgs-25.05-darwin` for darwin system (stable)
- Home Manager state version: 24.05
- Darwin state version: 6

### Home Manager Integration

- `useGlobalPkgs = true`: Uses system nixpkgs
- `useUserPackages = true`: Installs to user profile
- `backupFileExtension = "backup"`: Backs up conflicting files
- `enableNixpkgsReleaseCheck = false`: Disabled due to unstable/stable mix

### Homebrew Behavior

- Auto-updates on activation
- `cleanup = "zap"`: Aggressively removes undeclared packages (casks and formulas)
- Paths added to system PATH in `hosts/common/darwin/default.nix`

### TouchID for sudo

Enabled by default on all Darwin hosts via `security.pam.services.sudo_local.touchIdAuth = true`

## Typical Workflow

1. Make changes to relevant `.nix` files
2. Test build: `make build` (or `darwin-rebuild build --flake .#hostname`)
3. Review changes: `make diff`
4. Apply changes: `make switch`
5. Commit to git

For large changes, test on one host before applying to others.
