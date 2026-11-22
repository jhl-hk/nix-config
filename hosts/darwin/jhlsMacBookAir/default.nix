{lib, ...}:
#############################################################
#
#  jhlsMacBookAir -- MacBook Air
#
#############################################################
{
  imports = map lib.custom.relativeToRoot [
    "hosts/common/optional/common/llm.nix"
    "hosts/common/optional/darwin/cloudflare.nix"
    "hosts/common/optional/darwin/wakatime.nix"
    "hosts/common/optional/darwin/stay-awake.nix"
  ];

  hostSpec = {
    hostName = "jhlsMacBookAir";
    isMobile = true;
  };

  darwinHomebrew = {
    casks = ["grok-bot"];
    masApps."MoneyWiz Personal Finance" = 1511185140;
  };

  # Wallpaper: assets/tokai.png, the darwin default from hosts/common/core/darwin.nix.
}
