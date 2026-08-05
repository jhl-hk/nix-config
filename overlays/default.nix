{inputs, ...}:
#############################################################
#
#  Overlays
#
#  Five layers, stacked in order:
#    additions          -- home-grown packages under pkgs/common/, auto-discovered
#    customLib          -- attaches lib.custom onto pkgs.lib
#    modifications      -- hand-written nixpkgs package overrides, all platforms
#    linuxModifications -- overrides that only apply on Linux
#    unstable-packages  -- exposes pkgs.unstable.<x>
#
#############################################################
{
  # Drop in pkgs/common/<name>/package.nix and pkgs.<name> just works --
  # nothing here needs editing.
  additions = final: _prev:
    inputs.nixpkgs.lib.packagesFromDirectoryRecursive {
      inherit (final) callPackage;
      directory = ../pkgs/common;
    };

  # Makes lib.custom available inside the home-manager scope too.
  #
  # extraSpecialArgs.lib is not an option -- it replaces home-manager's own
  # lib wholesale, lib.hm disappears, and every HM module that touches
  # lib.hm.* (mako, plenty of services) dies with "attribute 'hm' missing".
  #
  # Hanging it off pkgs.lib avoids that: HM's lib is
  # `pkgs.lib.extend hmExtension`, so custom and hm both survive. The system
  # side gets it separately via specialArgs.lib in flake.nix.
  customLib = _final: prev: {
    lib =
      prev.lib
      // {
        custom = import ../lib {inherit (prev) lib;};
      };
  };

  # nixpkgs package overrides that apply on every platform.
  modifications = _final: _prev: {
    # e.g.
    # foo = _prev.foo.overrideAttrs (old: { patches = old.patches ++ [ ./fix.patch ]; });
  };

  # Linux only. optionalAttrs rather than mkIf -- the attribute is *literally
  # absent* on Darwin, which is stricter than mkIf and catches unknown-attribute
  # errors at evaluation time.
  linuxModifications = _final: prev:
    prev.lib.optionalAttrs prev.stdenv.isLinux {
      # e.g.
      # neovim = _final.unstable.neovim;
    };

  # When you just want a newer version of a package, reach for
  # pkgs.unstable.<x> instead of writing an override.
  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs {
      inherit (final.stdenv.hostPlatform) system;
      config.allowUnfree = true;
    };
  };
}
