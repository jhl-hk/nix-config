# Optional Modules

This directory contains optional configuration modules that can be selectively imported by hosts or users.

## Usage

In your host configuration (`hosts/darwin/<hostname>/default.nix` or `hosts/nixos/<hostname>/default.nix`), import optional modules like this:

```nix
{
  imports = [
    ../../common/optional/docker.nix
    ../../common/optional/development.nix
  ];
}
```

## Available Modules

- `development.nix` - Development tools and environments
- `docker.nix` - Docker and container tools (when available)
- Add more as needed...
