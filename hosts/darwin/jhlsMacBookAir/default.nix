{lib, ...}:
#############################################################
#
#  jhlsMacBookAir -- MacBook Air
#
#############################################################
{
  imports = map lib.custom.relativeToRoot [
    "hosts/common/optional/darwin/steam.nix"
    "hosts/common/optional/darwin/llm.nix"
    "hosts/common/optional/darwin/wakatime.nix"
  ];

  hostSpec = {
    hostName = "jhlsMacBookAir";
    isMobile = true;
  };

  # This machine used to set assets/HNDT3.jpg, but that file is not in the
  # repo (assets/ only has bg.jpeg and idebg.jpg), so it never worked.
  # Add the image to assets/ and uncomment the line below.
  # darwinWallpaper = lib.custom.relativeToRoot "assets/HNDT3.jpg";
}
