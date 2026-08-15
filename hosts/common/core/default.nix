{
  lib,
  pkgs,
  isDarwin,
  ...
}:
#############################################################
#
#  Common Core
#
#  Imported by every machine that has a system configuration -- so NixOS and
#  nix-darwin, but not the standalone home-manager lane (hosts/home/), which
#  has no system scope at all.
#
#  What happens here:
#
#    1. Platform dispatch -- modules/hosts/${platform} and
#       core/${platform}.nix are picked using the isDarwin passed down from
#       flake.nix. A specialArg rather than config.hostSpec.isDarwin, because
#       hostSpec is still being assembled at this point.
#
#    2. hostSpec population, via ./host-spec.nix. That lives in its own file
#       because flake.nix also feeds it to lib.custom.evalHostSpec for the
#       standalone lane, which cannot import this file.
#
#############################################################
let
  platform =
    if isDarwin
    then "darwin"
    else "nixos";
in {
  imports = map lib.custom.relativeToRoot [
    # Auto-scanned module layer (provides options, enables nothing)
    "modules/common"
    "modules/hosts/common"
    "modules/hosts/${platform}"

    # Platform-specific core
    "hosts/common/core/${platform}.nix"

    # Cross-platform core
    "hosts/common/core/host-spec.nix"
    "hosts/common/core/nix-settings.nix"
    "hosts/common/core/sops.nix"

    # User. default.nix is the platform-agnostic half; the platform half is
    # picked explicitly here -- Nix will not infer on its own that nixos.nix
    # is meant for NixOS.
    "hosts/common/users/jhl"
    "hosts/common/users/jhl/${platform}.nix"
  ];

  # What every machine gets
  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    wget
  ];
}
