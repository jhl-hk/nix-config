{
  config,
  hostSpec,
  ...
}:
#############################################################
#
#  niri -- config only, kept as a plain dotfiles directory
#
#  niri, DankMaterialShell and everything the binds spawn come from pacman.
#  This file only places ./niri at ~/.config/niri.
#
#  The directory is an out-of-store symlink into this checkout, not a store
#  copy. Edits take effect on save, the same as before, and land in git.
#  DankMaterialShell writes ./niri/dms/*.kdl at runtime; those writes land
#  in the repo too, so commit them along with your own edits.
#  Per-machine state is git-ignored: dms/outputs.kdl, dms/colors.kdl and
#  local/ (the touchpad switch). See ./niri/.gitignore.
#
#  The whole directory is linked, not single files. A tool that saves by
#  writing a temp file and renaming it replaces a linked *file* with a plain
#  copy; inside a linked directory the rename stays in the repo.
#
#  The link target is absolute, so the repo must be cloned at the path below
#  on every machine.
#
#############################################################
let
  repoDir = "${hostSpec.home}/Documents/nix-src/nix-config";
in {
  xdg.configFile."niri".source =
    config.lib.file.mkOutOfStoreSymlink "${repoDir}/home/jhl/common/optional/desktop/niri";
}
