{
  config,
  lib,
  pkgs,
  ...
}:
#############################################################
#
#  Darwin Core
#  所有 macOS 机器共享。由 hosts/common/core/default.nix 按平台挑中。
#
#############################################################
{
  imports = [
    ./darwin/system-defaults.nix
    ./darwin/apps.nix
  ];

  # nix-darwin 要**整数**。NixOS 那边的 system.stateVersion 是字符串，
  # 写混了会在求值期报类型错误。这个值跟的是最初安装时的版本，
  # 不读 nix-darwin release notes 不要动它 —— 它钉的是迁移逻辑，不是当前版本。
  system.stateVersion = 6;

  # 主机名三件套统一从 hostSpec 来，host 文件只需要写 hostSpec.hostName。
  networking = {
    hostName = config.hostSpec.hostName;
    computerName = config.hostSpec.hostName;
  };
  system.defaults.smb.NetBIOSName = config.hostSpec.hostName;

  # Darwin 上用 nix.optimise.automatic，不是 auto-optimise-store
  nix.optimise.automatic = true;

  # sudo 支持 TouchID
  security.pam.services.sudo_local.touchIdAuth = true;

  # 生成 /etc/zshrc，加载 nix-darwin 环境
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    # 关掉默认的 compinit，交给 home-manager 那边处理，
    # 免得 nix store 路径触发 insecure directory 检查
    enableGlobalCompInit = false;
    promptInit = ''
      eval "$(${pkgs.starship}/bin/starship init zsh)"
    '';
  };

  # Homebrew 的路径要进系统 PATH。
  #
  # 位置很讲究，必须夹在 nix 的路径和 /usr/bin 之间：
  #   排在 nix 前面    -> brew 的 git/openssh 盖掉 nix 的
  #   排在 /usr/bin 后 -> Xcode 的 /usr/bin/git 盖掉 brew 的
  #
  # nix-darwin 在 modules/environment/default.nix:139 分两次定义：
  #   nix profiles   默认序 1000
  #   /usr/bin 那批  mkOrder 1200
  # 普通定义也是 1000，同序之间按模块顺序排 —— 重排 imports 就会翻车
  # （实测过）。用 mkOrder 1100 钉死在中间，跟模块顺序无关。
  environment.systemPath = lib.mkOrder 1100 [
    "/opt/homebrew/bin"
    "/opt/homebrew/sbin"
    "/opt/homebrew/opt/openssh/bin"
  ];

  environment.systemPackages = with pkgs; [
    starship

    # Omni CLI。不走 Homebrew：siderolabs/tap 的 omnictl 没有 bottle，
    # brew 会当成 build-from-source，在 macOS seed 版上撞 Xcode 版本检查。
    # unstable 里是 1.9.3，跟 tap 同版本。
    unstable.omnictl
  ];

  # 壁纸。host 文件里普通赋值即可覆盖（modules/hosts/darwin/wallpaper）。
  darwinWallpaper = lib.mkDefault (lib.custom.relativeToRoot "assets/bg.jpeg");
}
