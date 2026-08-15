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

  # Evaluate the hostSpec option tree on its own, outside NixOS / nix-darwin.
  #
  # The standalone home-manager lane (hosts/home/, machines running nix on top
  # of another distro) has no system configuration, so there is no module tree
  # for hosts/common/core to run in -- yet home modules still expect the same
  # hostSpec attrset through extraSpecialArgs. Feeding the schema to a bare
  # evalModules keeps one definition of it: same types, same defaults, same
  # assertions, and no second copy to drift out of step.
  #
  #   lib.custom.evalHostSpec {
  #     specialArgs = { inherit inputs lib pkgs; isDarwin = false; };
  #     modules = [ ./hosts/common/core/host-spec.nix ./hosts/home/<Name> ];
  #   }
  #
  # Returns the plain attrset, not the evalModules result -- the caller wants
  # something it can hand straight to extraSpecialArgs.
  evalHostSpec = {
    specialArgs,
    modules,
  }: let
    evaluated = lib.evalModules {
      inherit specialArgs;
      modules =
        [
          ../modules/common/host-spec.nix

          # host-spec.nix writes to `assertions`, an option that NixOS,
          # nix-darwin and home-manager each declare for it. A bare evalModules
          # declares nothing, so without this the definition is rejected as an
          # unknown option. Same type nixpkgs uses in
          # nixos/modules/misc/assertions.nix.
          {
            options.assertions = lib.mkOption {
              type = lib.types.listOf lib.types.unspecified;
              internal = true;
              default = [];
              description = "Assertions to check, mirroring the NixOS option of the same name.";
            };
          }
        ]
        ++ modules;
    };

    failed = builtins.filter (a: !a.assertion) evaluated.config.assertions;
  in
    # Nothing checks `assertions` in a bare evalModules, so do it here. Skip
    # this and a violated hostSpec assertion is simply ignored on the
    # standalone lane while it aborts the build on the system lanes.
    if failed == []
    then evaluated.config.hostSpec
    else
      throw ''
        hostSpec assertions failed:
        ${lib.concatMapStringsSep "\n" (a: "  - ${a.message}") failed}'';
}
