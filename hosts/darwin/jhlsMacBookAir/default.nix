{lib, ...}:
#############################################################
#
#  jhlsMacBookAir -- MacBook Air
#
#############################################################
{
  imports = map lib.custom.relativeToRoot [
    "hosts/common/optional/darwin/llm.nix"
    "hosts/common/optional/darwin/cloudflare.nix"
    "hosts/common/optional/darwin/wakatime.nix"
    "hosts/common/optional/darwin/openclaw.nix"
  ];

  # Not zap. This machine is reached over Tailscale and administered entirely
  # over ssh, so an activation that deletes an undeclared package's data has
  # no console to fall back on. `uninstall` keeps the Brewfile authoritative
  # -- undeclared packages still go -- without taking their configuration
  # with them, so recovering from a wrong declaration is a reinstall rather
  # than a reconstruction.
  darwinHomebrew.cleanup = "uninstall";

  hostSpec = {
    hostName = "jhlsMacBookAir";
    isMobile = true;
  };

  # This machine used to set assets/HNDT3.jpg, but that file is not in the
  # repo (assets/ only has bg.jpeg and idebg.jpg), so it never worked.
  # Add the image to assets/ and uncomment the line below.
  # darwinWallpaper = lib.custom.relativeToRoot "assets/HNDT3.jpg";
}
