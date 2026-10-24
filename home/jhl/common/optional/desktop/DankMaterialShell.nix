{
  config,
  hostSpec,
  ...
}:
#############################################################
#
#  DankMaterialShell -- config only, kept as a plain dotfiles directory
#
#  DMS itself comes from pacman. This file only places ./DankMaterialShell
#  at ~/.config/DankMaterialShell, the same way niri.nix places ./niri.
#
#  Out-of-store directory symlink: DMS rewrites settings.json and
#  plugin_settings.json whenever something changes in its settings UI, and
#  those writes land in this checkout. Commit them like any other edit.
#
#  plugins/zuluClock is a local bar widget ("1517z 0017j • Sat 24 Oct 26")
#  that takes the place of the built-in "clock" widget in barConfigs.
#
#############################################################
let
  repoDir = "${hostSpec.home}/Documents/nix-src/nix-config";
in {
  xdg.configFile."DankMaterialShell".source =
    config.lib.file.mkOutOfStoreSymlink "${repoDir}/home/jhl/common/optional/desktop/DankMaterialShell";
}
