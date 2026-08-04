{
  lib,
  hostSpec,
  ...
}:
#############################################################
#
#  Home Core -- 每台机器都要的基线
#
#  这里的 imports 是**手写**的，不是 scanPaths。core 是「我在哪都想要
#  的东西」，手写一份清单可以一眼看完自己的 dotfile 面积。
#  想按机器开关的东西放 common/optional/。
#
#  hostSpec 是通过 extraSpecialArgs 传进来的**函数参数**，不是选项 ——
#  home 模块直接在函数头解构 { hostSpec, ... }，不要去读 NixOS 的 config。
#
#############################################################
let
  platform =
    if hostSpec.isDarwin
    then "darwin"
    else "nixos";
in {
  imports = [
    # 提供 options 的 home 模块，自动扫描
    (lib.custom.relativeToRoot "modules/home")

    # 平台那半。这行是普通的路径插值，不是魔法 ——
    # 重命名 darwin.nix / nixos.nix 会让对应平台直接求值失败。
    ./${platform}.nix

    ./git.nix
    ./ssh.nix
    ./zsh.nix
    ./starship.nix
    ./tmux.nix
    ./claude.nix
  ];

  home = {
    username = hostSpec.username;
    homeDirectory = hostSpec.home;
    stateVersion = "26.05";

    # 我们混用 unstable 的 nixpkgs 和 stable 的 darwin，关掉版本一致性检查
    enableNixpkgsReleaseCheck = false;

    sessionVariables = {
      EDITOR = "vim";
    };

    # git 提交签名校验用的 allowed_signers。内容是公钥，
    # 但属于身份数据，所以放在 nix-secrets 的明文半区。
    file.".ssh/allowed_signers".text = lib.concatLines hostSpec.sshAllowedSigners;
  };

  programs.home-manager.enable = true;
}
