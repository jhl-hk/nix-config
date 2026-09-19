{lib, ...}:
#############################################################
#
#  SeandeMac-Studio -- Mac Studio (Taizhou)
#
#############################################################
{
  imports = map lib.custom.relativeToRoot [
    "hosts/common/optional/darwin/desktop.nix"
    "hosts/common/optional/darwin/vscode.nix"
    "hosts/common/optional/darwin/dev-extras.nix"
    "hosts/common/optional/darwin/llm.nix"
    "hosts/common/optional/darwin/cloudflare.nix"
    "hosts/common/optional/darwin/wakatime.nix"

    # Needs the `codex` cask from desktop.nix above -- keep the pair.
    "hosts/common/optional/darwin/codex.nix"
  ];

  hostSpec = {
    hostName = "SeandeMac-Studio";
    isMobile = false;
  };

  # This machine runs a seed build (26A5388g at the time of writing), which
  # mas cannot install into. Nothing to declare for that any more:
  # modules/hosts/darwin/homebrew/mas.nix reads sw_vers at activation time
  # and skips the App Store apps by itself. `just check-beta` reports what
  # that check currently sees.
}
