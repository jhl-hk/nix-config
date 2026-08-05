{
  inputs,
  lib,
  pkgs,
  isDarwin,
  ...
}:
#############################################################
#
#  Common Core
#
#  Imported by every machine. Two repo-wide things happen in this file:
#
#    1. Platform dispatch -- modules/hosts/${platform} and
#       core/${platform}.nix are picked using the isDarwin passed down from
#       flake.nix. A specialArg rather than config.hostSpec.isDarwin, because
#       hostSpec is still being assembled at this point.
#
#    2. hostSpec population -- identity and topology data is inherited from
#       inputs.nix-secrets in one place. After this, every module reads
#       config.hostSpec.<x> and never touches inputs.nix-secrets again.
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
    "hosts/common/core/nix-settings.nix"
    "hosts/common/core/sops.nix"

    # User. default.nix is the platform-agnostic half; the platform half is
    # picked explicitly here -- Nix will not infer on its own that nixos.nix
    # is meant for NixOS.
    "hosts/common/users/jhl"
    "hosts/common/users/jhl/${platform}.nix"
  ];

  hostSpec = {
    username = "jhl";
    handle = "jhl-hk";
    inherit isDarwin;

    inherit
      (inputs.nix-secrets)
      domain
      email
      userFullName
      sshAllowedSigners
      networking
      networkInfo
      serviceInfo
      ;
  };

  # What every machine gets
  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    wget
  ];
}
