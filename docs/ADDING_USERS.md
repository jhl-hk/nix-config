# Adding New Users

This guide explains how to add new users to your Nix configuration.

## Quick Steps

1. **Copy the user template:**
```bash
cp -r users/_template users/newusername
cp -r home/_template home/newusername
```

2. **Edit system user config:**
```bash
# Edit users/newusername/default.nix
# Replace USERNAME with the actual username
# Replace FULL_NAME with the user's full name
```

3. **Edit home configuration:**
```bash
# Edit home/newusername/default.nix
# Replace USERNAME, FULL_NAME, and EMAIL
# Customize packages and settings
```

4. **Assign user to hosts in flake.nix:**

For existing host:
```nix
darwinConfigurations = {
  macbook = mkDarwin {
    hostname = "macbook";
    username = "newusername";  # Change this
  };
};
```

Or create a new host with the new user:
```nix
darwinConfigurations = {
  newmachine = mkDarwin {
    hostname = "newmachine";
    username = "newusername";
  };
};
```

5. **Build and switch:**
```bash
darwin-rebuild switch --flake .#hostname
# or
sudo nixos-rebuild switch --flake .#hostname
```

## Multi-User Scenarios

### Multiple Users on One Machine

For systems with multiple users, you can:

1. Create separate host configurations for each user:
```nix
darwinConfigurations = {
  macbook-alice = mkDarwin {
    hostname = "macbook";
    username = "alice";
  };
  
  macbook-bob = mkDarwin {
    hostname = "macbook";
    username = "bob";
  };
};
```

2. Each user runs their own rebuild:
```bash
# Alice
darwin-rebuild switch --flake .#macbook-alice

# Bob
darwin-rebuild switch --flake .#macbook-bob
```

### Same User Across Multiple Machines

One user can be used across multiple hosts:

```nix
darwinConfigurations = {
  laptop = mkDarwin {
    hostname = "laptop";
    username = "alice";
  };
  
  desktop = mkDarwin {
    hostname = "desktop";
    username = "alice";
  };
  
  server = mkNixOS {
    hostname = "server";
    username = "alice";
  };
};
```

## Customizing User Configurations

### User-Specific Packages

Add packages in `home/username/default.nix`:

```nix
home.packages = with pkgs; [
  vscode
  spotify
  discord
];
```

### User-Specific Programs

Create program-specific configs:

```bash
mkdir -p home/username/programs
```

```nix
# home/username/programs/neovim.nix
{ pkgs, ... }:
{
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    plugins = with pkgs.vimPlugins; [
      vim-nix
      telescope-nvim
    ];
  };
}
```

Import in `home/username/default.nix`:
```nix
{
  imports = [
    ./programs/neovim.nix
  ];
}
```

### User-Specific Shell Configuration

```nix
# home/username/default.nix
programs.zsh = {
  enable = true;
  shellAliases = {
    dev = "cd ~/Development";
    rebuild = "darwin-rebuild switch --flake ~/.config/nix-config";
  };
  
  initExtra = ''
    # Custom shell initialization
    export PATH="$HOME/.local/bin:$PATH"
  '';
};
```

## Home Manager Features

Home Manager allows per-user configuration of:

- **Shell**: zsh, bash, fish
- **Editors**: vim, neovim, emacs, vscode
- **Terminals**: alacritty, kitty, wezterm
- **Git**: configuration, aliases, signing
- **SSH**: config, keys
- **XDG**: directories, mime types
- **And much more**: See [Home Manager options](https://nix-community.github.io/home-manager/options.html)

## Different Users for Work vs Personal

```nix
# Work user with professional tools
home/john.doe/default.nix:
{
  home.packages = with pkgs; [
    slack
    zoom-us
    teams
  ];
  
  programs.git = {
    userEmail = "john.doe@company.com";
  };
}

# Personal user with different config
home/john/default.nix:
{
  home.packages = with pkgs; [
    steam
    discord
  ];
  
  programs.git = {
    userEmail = "john@personal.com";
  };
}
```

## Tips

- Keep sensitive data out of the repository
- Use consistent usernames across hosts when possible
- Document any special user requirements in comments
- Consider using sops-nix for user secrets (SSH keys, API tokens, etc.)

## Troubleshooting

### User not created on system

On NixOS, ensure `isNormalUser = true` is set in the user configuration.

### Home Manager not activating

Check that:
- Home Manager is properly imported in flake.nix
- The username matches in both system and home configurations
- The home directory path is correct for your OS

### Permission issues

- Ensure the user has necessary group memberships
- On NixOS, add user to required groups in `extraGroups`
- On Darwin, ensure user has admin privileges if needed
