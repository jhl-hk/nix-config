{lib, ...}:
#############################################################
#
#  lib.custom
#
#  Attached as `lib.custom` via `nixpkgs.lib.extend` in flake.nix, so any
#  module that receives `lib` can use it directly with no extra import.
#
#############################################################
{
  # Resolve a **string** fragment into a path relative to the flake root.
  #
  #   lib.custom.relativeToRoot "hosts/common/core"   -- correct
  #   lib.custom.relativeToRoot ./hosts/common/core   -- wrong, lib.path.append wants a string
  #
  # A string rather than a path literal keeps the path's identity stable in
  # the store.
  relativeToRoot = lib.path.append ../.;

  # List everything under `path` that can go straight into `imports`:
  # subdirectories, plus .nix files other than `default.nix`.
  #
  # Excluding default.nix is the crucial part -- scanPaths is called *by* a
  # default.nix, so without the exclusion it would recurse forever.
  #
  # Effect: any file or directory sitting next to the default.nix that calls
  # scanPaths gets imported automatically, with nothing to register.
  # Everything under modules/ relies on this.
  scanPaths = path:
    builtins.map (f: path + "/${f}") (
      builtins.attrNames (
        lib.attrsets.filterAttrs (
          name: type: (type == "directory") || ((name != "default.nix") && (lib.strings.hasSuffix ".nix" name))
        ) (builtins.readDir path)
      )
    );
}
