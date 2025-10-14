# Nix Configuration

Multi-host, multi-user NixOS and nix-darwin configuration using flakes.

## Structure

```
.
├── flake.nix                 # Main flake configuration
├── hosts/                    # Host-specific configurations
│   ├── common/              
│   │   ├── core/            # Core configs for all hosts
│   │   ├── darwin/          # Common macOS configs
│   │   └── optional/        # Optional modules for hosts
│   ├── darwin/              # macOS host definitions
│   │   └── jhlsMacBookAir/
│   └── nixos/               # NixOS host definitions (future)
├── users/                    # System-level user configurations
│   └── jhl/
├── home/                     # Home Manager user configurations
│   ├── jhl/
│   └── common/
│       └── optional/        # Optional home modules
└── modules/                  # Legacy modules (to be migrated)
```

## Design Philosophy

Based on [EmergentMind/nix-config](https://github.com/EmergentMind/nix-config) principles:

- **Modular**: Configurations split into reusable modules
- **Scalable**: Easy to add new hosts and users
- **Declarative**: Everything defined in code
- **Core + Optional**: Required configs in `core/`, extras in `optional/`

## Quick Start

### Initial Setup

```bash
# Clone this repository
git clone <your-repo> ~/.config/nix-config
cd ~/.config/nix-config

# For macOS - Build and switch
make switch

# Or manually:
darwin-rebuild switch --flake .#jhlsMacBookAir
```

### Daily Usage

```bash
# Rebuild system
make switch

# Update flake inputs
make update

# Clean old generations
make clean

# Show system info
make info
```

## Adding New Hosts

### macOS (Darwin)

1. Create host directory:
```bash
mkdir -p hosts/darwin/new-hostname
```

2. Create `hosts/darwin/new-hostname/default.nix`:
```nix
{ pkgs, ... }:
{
  imports = [
    ../../common/optional/development.nix  # Optional modules
  ];
  
  networking.hostName = "new-hostname";
  # Add host-specific config...
}
```

3. Add to `flake.nix`:
```nix
darwinConfigurations = {
  new-hostname = mkDarwin {
    hostname = "new-hostname";
    system = "aarch64-darwin";  # or x86_64-darwin
    username = "your-username";
  };
};
```

### NixOS

1. Create host directory:
```bash
mkdir -p hosts/nixos/new-hostname
```

2. Create `hosts/nixos/new-hostname/default.nix` with your hardware and system config

3. Add to `flake.nix` in `nixosConfigurations` section

## Adding New Users

1. Create system user config:
```bash
mkdir -p users/newuser
```

2. Create `users/newuser/default.nix`:
```nix
{ pkgs, ... }:
{
  users.users.newuser = {
    home = "/Users/newuser";  # or /home/newuser on Linux
    description = "New User";
    shell = pkgs.zsh;
  };
  
  # Darwin-specific
  system.primaryUser = "newuser";
  nix.settings.trusted-users = [ "newuser" ];
}
```

3. Create home config:
```bash
cp -r home/jhl home/newuser
```

4. Edit `home/newuser/default.nix` and customize

## Customization

### Host-specific packages

Edit `hosts/darwin/<hostname>/default.nix` or `hosts/nixos/<hostname>/default.nix`

### User-specific packages

Edit `home/<username>/default.nix`

### System-wide packages

Edit `hosts/common/darwin/default.nix` or create optional modules

## Managing Multiple Devices

Each device can have different configurations while sharing common settings:

```nix
# Example: MacBook with development tools
darwinConfigurations.macbook = mkDarwin {
  hostname = "macbook";
  username = "jhl";
  modules = [
    ./hosts/common/optional/development.nix
  ];
};

# Example: Mac Mini as server
darwinConfigurations.mini = mkDarwin {
  hostname = "mini";
  username = "jhl";
  modules = [
    # Different optional modules
  ];
};
```

## Tips

- Keep sensitive data out of the repo (use sops-nix for secrets)
- Use `optional/` modules for non-essential configs
- Test changes with `darwin-rebuild build --flake .#hostname` before switching
- Commit your configuration changes to git

## Resources

- [Nix Darwin Manual](https://daiderd.com/nix-darwin/manual/index.html)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [NixOS Options](https://search.nixos.org/options)
