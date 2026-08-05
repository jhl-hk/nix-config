{lib, ...}:
#############################################################
#
#  SeandeMac-Studio -- Mac Studio (Taizhou)
#
#############################################################
{
  imports = map lib.custom.relativeToRoot [
    "hosts/common/optional/darwin/llm.nix"
    "hosts/common/optional/darwin/wakatime.nix"
  ];

  hostSpec = {
    hostName = "SeandeMac-Studio";
    isMobile = false;
  };

  # macOS 27.0 (26A5388g), on the 27seed track.
  # mas cannot install on seed builds, so masApps is skipped entirely.
  # `just check-beta` reports which kind this machine is on right now.
  darwinHomebrew.macosBeta = true;
}
