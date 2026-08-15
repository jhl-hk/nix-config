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

  # Puts lib.custom on pkgs.lib, for code that reads pkgs.lib directly.
  #
  # It does **not** feed the home-manager module system, despite what an
  # earlier version of this comment claimed. HM builds its module lib as
  # `stdlib-extended <the lib it was handed>`, i.e. `lib.extend (…: { hm = …; })`,
  # and extend rebuilds from lib's *fixpoint* -- so the `custom` added below
  # with `//` is dropped again. Measured against this very pkgs:
  #
  #   pkgs.lib ? custom                      => true
  #   (pkgs.lib.extend (_: _: {})) ? custom  => false
  #
  # What actually delivers lib.custom to home-manager is the lib HM extends:
  # specialArgs.lib on the system lanes (nix-darwin forwards it), and the
  # top-level `lib` argument of homeManagerConfiguration on the standalone
  # lane. extraSpecialArgs.lib is wrong on both -- it replaces the extended
  # result and lib.hm disappears, so every HM module touching lib.hm.* (mako,
  # plenty of services) dies with "attribute 'hm' missing".
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
