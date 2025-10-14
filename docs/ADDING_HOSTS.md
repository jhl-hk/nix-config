# Adding New Hosts

This guide explains how to add new machines to your Nix configuration.

## Quick Steps

### For macOS (Darwin)

1. **Copy the template:**
```bash
cp -r hosts/darwin/_template hosts/darwin/your-hostname
```

2. **Edit the configuration:**
```bash
# Edit hosts/darwin/your-hostname/default.nix
# Replace HOSTNAME with your actual hostname
# Replace DESCRIPTION with a brief description
```

3. **Add to flake.nix:**
```nix
darwinConfigurations = {
  # ... existing configurations ...
  
  your-hostname = mkDarwin {
    hostname = "your-hostname";
    system = "aarch64-darwin";  # or "x86_64-darwin" for Intel Macs
    username = "your-username";
  };
};
```

4. **Build and test:**
```bash
# Build without switching
darwin-rebuild build --flake .#your-hostname

# If successful, switch
darwin-rebuild switch --flake .#your-hostname
```

### For NixOS

1. **Generate hardware configuration:**
```bash
# On the target machine
nixos-generate-config --show-hardware-config > hardware-configuration.nix
```

2. **Copy the template:**
```bash
cp -r hosts/nixos/_template hosts/nixos/your-hostname
```

3. **Add hardware config:**
```bash
# Move the generated hardware-configuration.nix to:
mv hardware-configuration.nix hosts/nixos/your-hostname/
```

4. **Edit the configuration:**
```bash
# Edit hosts/nixos/your-hostname/default.nix
# Replace HOSTNAME and customize as needed
```

5. **Add to flake.nix:**
```nix
nixosConfigurations = {
  # ... existing configurations ...
  
  your-hostname = mkNixOS {
    hostname = "your-hostname";
    system = "x86_64-linux";  # or "aarch64-linux" for ARM
    username = "your-username";
  };
};
```

6. **Build and switch:**
```bash
sudo nixos-rebuild switch --flake .#your-hostname
```

## Adding Optional Modules

Import optional modules in your host configuration:

```nix
{
  imports = [
    ../../common/optional/development.nix
    ../../common/optional/docker.nix
  ];
}
```

## Host-Specific Customization

### Different System Configurations

Each host can have unique settings:

```nix
# hosts/darwin/work-laptop/default.nix
{
  imports = [
    ../../common/optional/development.nix
  ];
  
  # Work-specific settings
  networking.hostName = "work-laptop";
  
  environment.systemPackages = with pkgs; [
    slack
    zoom-us
  ];
}
```

### Different Users per Host

Specify different users for different hosts:

```nix
darwinConfigurations = {
  personal-mac = mkDarwin {
    hostname = "personal-mac";
    username = "john";
  };
  
  work-mac = mkDarwin {
    hostname = "work-mac";
    username = "john.doe";
  };
};
```

## Testing Changes

Always test before switching:

```bash
# Darwin
darwin-rebuild build --flake .#hostname
./result/sw/bin/darwin-rebuild switch --flake .#hostname

# NixOS
sudo nixos-rebuild test --flake .#hostname
```

## Troubleshooting

### Build fails with "does not provide attribute"

- Ensure the hostname in flake.nix matches the directory name
- Check that all imports exist

### Permission denied

- On macOS: make sure you have admin rights
- On NixOS: use `sudo` for nixos-rebuild commands

### Hardware not detected

- Re-generate hardware-configuration.nix on the target machine
- Check that all necessary kernel modules are included
