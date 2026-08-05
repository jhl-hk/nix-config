{
  config,
  lib,
  ...
}:
#############################################################
#
#  Desktop wallpaper
#
#  system-defaults.nix and jhlsMacBookAir/default.nix each used to write their
#  own system.activationScripts.postActivation.text to set the wallpaper. That
#  option concatenates text, so both fragments ran and which one won depended
#  on ordering -- and both referenced a path under
#  ~/Documents/nix-config/assets/, which no longer exists.
#
#  As a single option there is exactly one definition, and overriding is a
#  plain assignment. The path is a nix path rather than a string, so the image
#  is copied into the store and no longer depends on the home directory layout.
#
#############################################################
let
  cfg = config.darwinWallpaper;
in {
  options.darwinWallpaper = lib.mkOption {
    type = lib.types.nullOr lib.types.path;
    default = null;
    example = lib.literalExpression ''lib.custom.relativeToRoot "assets/bg.jpeg"'';
    description = "Wallpaper for every desktop and Space. null means leave the wallpaper alone.";
  };

  config = lib.mkIf (cfg != null) {
    system.activationScripts.postActivation.text = ''
      # Set the wallpaper. osascript must run as the logged-in user, but
      # activation runs as root.
      sudo -u ${config.hostSpec.username} /usr/bin/osascript -e \
        'tell application "System Events" to tell every desktop to set picture to "${cfg}"' || true
    '';
  };
}
