# Home Manager Optional Modules

This directory contains optional Home Manager modules that can be selectively imported by users.

## Usage

In your user's home configuration (`home/<username>/default.nix`), import optional modules:

```nix
{
  imports = [
    ../common/optional/vscode.nix
    ../common/optional/terminals.nix
  ];
}
```

## Available Modules

Add user-specific optional configurations here like:
- IDE configurations
- Terminal emulators
- Development environments
- Personal tools
