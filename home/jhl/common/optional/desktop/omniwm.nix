{
  config,
  hostSpec,
  ...
}:
#############################################################
#
#  OmniWM -- config only
#
#  The app comes from the omniwm cask
#  (hosts/common/optional/darwin/omniwm.nix -- keep the pair).
#  This file links ./omniwm to ~/.config/omniwm.
#
#  Out-of-store directory symlink: OmniWM rewrites settings.toml when its
#  settings UI changes, and those writes land in this checkout.
#
#  Tiling transitions are off (animationsEnabled = false). Overview and
#  Quake terminal animations retain their own settings.
#
#  Hotkeys bind physical QWERTY keycodes; letters are chosen so the
#  Colemak positions match the niri binds.
#
#############################################################
let
  repoDir = "${hostSpec.home}/Documents/nix-src/nix-config";
in {
  xdg.configFile."omniwm".source =
    config.lib.file.mkOutOfStoreSymlink "${repoDir}/home/jhl/common/optional/desktop/omniwm";
}
