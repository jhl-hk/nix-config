# Migration Summary

## What Changed

Your nix-config has been restructured to support multiple devices and users, following the design philosophy of [EmergentMind/nix-config](https://github.com/EmergentMind/nix-config).

### New Structure

```
nix-config/
├── flake.nix                 # Refactored with mkDarwin/mkNixOS helpers
├── hosts/
│   ├── common/
│   │   ├── core/            # Settings for ALL hosts
│   │   ├── darwin/          # Settings for ALL macOS hosts
│   │   └── optional/        # Optional modules for hosts
│   ├── darwin/
│   │   ├── _template/       # Template for new macOS hosts
│   │   └── jhlsMacBookAir/  # Your current Mac
│   └── nixos/
│       └── _template/       # Template for new NixOS hosts
├── users/
│   ├── _template/           # Template for new users
│   └── jhl/                 # System-level user config
├── home/
│   ├── _template/           # Template for new home configs
│   ├── common/optional/     # Optional home modules
│   └── jhl/                 # Home Manager config for jhl
│       ├── programs/        # Program configurations
│       └── shell/           # Shell configurations
└── docs/
    ├── ADDING_HOSTS.md      # Guide for adding hosts
    ├── ADDING_USERS.md      # Guide for adding users
    └── MIGRATION_SUMMARY.md # This file
```

### Key Features

1. **Multi-Host Support**: Easy to add new machines (Darwin or NixOS)
2. **Multi-User Support**: Each user can have their own configuration
3. **Modular Design**: 
   - `core/` = required for all hosts
   - `darwin/` = macOS-specific settings
   - `optional/` = pick and choose features
4. **Home Manager Integration**: Per-user dotfiles and packages
5. **Template System**: Quick setup for new hosts/users
6. **Better Organization**: Clear separation of concerns

## Old vs New

### Old Structure
- Everything in `modules/` (flat)
- Single host hardcoded in flake.nix
- No Home Manager integration
- No user separation

### New Structure
- Hierarchical organization
- Dynamic host/user creation via helpers
- Full Home Manager integration
- Clear separation of system/user configs

## What Was Migrated

Your existing configuration has been reorganized:

- `modules/nix-core.nix` → `hosts/common/core/nix-settings.nix`
- `modules/system.nix` → `hosts/common/darwin/system-defaults.nix`
- `modules/apps.nix` → `hosts/common/darwin/homebrew.nix`
- `modules/host-users.nix` → `users/jhl/default.nix`

**Note**: Old modules in `modules/` still exist but are no longer used. You can safely delete them after verifying everything works.

## Next Steps

### 1. Test the New Configuration

```bash
# Dry run first
make build

# If successful, apply
make switch
```

### 2. Clean Up Old Files (Optional)

After verifying everything works:

```bash
rm -rf modules/
git add -u
git commit -m "Remove old module structure"
```

### 3. Customize Your Setup

- Edit `home/jhl/programs/git.nix` with your real email
- Add more packages to `home/jhl/default.nix`
- Customize shell aliases in `home/jhl/shell/zsh.nix`
- Adjust system defaults in `hosts/common/darwin/system-defaults.nix`

### 4. Add More Hosts (When Needed)

Follow the guides:
- `docs/ADDING_HOSTS.md` for new machines
- `docs/ADDING_USERS.md` for new users

## Example: Adding a Second Mac

```bash
# 1. Copy template
cp -r hosts/darwin/_template hosts/darwin/work-macbook

# 2. Edit hosts/darwin/work-macbook/default.nix
# Replace HOSTNAME with "work-macbook"

# 3. Add to flake.nix
# In darwinConfigurations:
work-macbook = mkDarwin {
  hostname = "work-macbook";
  system = "aarch64-darwin";
  username = "jhl";  # or different user
};

# 4. On that machine, run:
darwin-rebuild switch --flake .#work-macbook
```

## Example: Adding a Second User

```bash
# 1. Copy templates
cp -r users/_template users/alice
cp -r home/_template home/alice

# 2. Edit both files, replacing USERNAME/EMAIL

# 3. Create a host config for that user
# In flake.nix:
jhlsMacBookAir-alice = mkDarwin {
  hostname = "jhlsMacBookAir";
  username = "alice";
};

# 4. Alice runs:
darwin-rebuild switch --flake .#jhlsMacBookAir-alice
```

## Benefits

1. **Scalability**: Add 10 machines with minimal duplication
2. **Maintainability**: Shared configs in `common/`, unique in host dirs
3. **Flexibility**: Mix and match optional modules per host
4. **User Isolation**: Each user's packages/dotfiles separate
5. **Version Control**: Track per-host and per-user changes clearly

## Troubleshooting

### Build Fails

```bash
# Check for syntax errors
nix flake check

# Show detailed errors
nix build .#darwinConfigurations.jhlsMacBookAir.system --show-trace
```

### Home Manager Issues

If Home Manager doesn't activate:
- Check username matches in `users/` and `home/`
- Verify home directory path is correct
- See Home Manager logs: `journalctl --user -u home-manager-*`

### Import Errors

If modules can't be found:
- Ensure all new files are tracked by git: `git add -A`
- Check import paths are relative and correct

## Resources

- [Main README](../README.md) - Quick start and usage
- [Adding Hosts Guide](./ADDING_HOSTS.md) - Detailed host setup
- [Adding Users Guide](./ADDING_USERS.md) - Detailed user setup
- [Nix Darwin Manual](https://daiderd.com/nix-darwin/manual/index.html)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)

## Questions?

Check if your issue is covered in:
1. The README.md
2. The docs/ directory guides
3. Nix Darwin / Home Manager documentation

Good luck with your multi-host, multi-user Nix configuration! 🚀
