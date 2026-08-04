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
#  每台机器都会导入这里。整个仓库的两件事在这个文件发生：
#
#    1. 平台分派 —— modules/hosts/${platform} 和 core/${platform}.nix
#       靠 flake.nix 传进来的 isDarwin 选。用 specialArg 而不是
#       config.hostSpec.isDarwin，因为 hostSpec 这时候还在组装中。
#
#    2. hostSpec 灌注 —— 身份和拓扑数据从 inputs.nix-secrets 一次性
#       inherit 进来。之后所有模块一律读 config.hostSpec.<x>，
#       不再直接碰 inputs.nix-secrets。
#
#############################################################
let
  platform =
    if isDarwin
    then "darwin"
    else "nixos";
in {
  imports = map lib.custom.relativeToRoot [
    # 自动扫描的模块层（提供 options，不打开任何功能）
    "modules/common"
    "modules/hosts/common"
    "modules/hosts/${platform}"

    # 平台专属的 core
    "hosts/common/core/${platform}.nix"

    # 跨平台的 core
    "hosts/common/core/nix-settings.nix"
    "hosts/common/core/sops.nix"

    # 用户。default.nix 是平台无关的那半，平台那半由这里显式挑 ——
    # Nix 不会自己推断 nixos.nix 是给 NixOS 用的。
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

  # 每台机器都要有的东西
  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    wget
  ];
}
