{
  config,
  lib,
  ...
}:
#############################################################
#
#  Homebrew
#
#  能力层：只提供选项和接线，不含任何具体的包名。
#  清单数据在 hosts/common/core/darwin/apps.nix，
#  单机追加的在 hosts/common/optional/darwin/*.nix。
#
#  taps / brews / casks 都是 listOf，模块系统会把多处定义**拼接**起来，
#  所以任意多个 optional 文件都能各自往里加东西，不用互相知道。
#
#############################################################
let
  cfg = config.darwinHomebrew;
  inherit (lib) mkOption types;
in {
  options.darwinHomebrew = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "由 nix-darwin 管理 Homebrew。";
    };

    macosBeta = mkOption {
      type = types.bool;
      default = false;
      description = ''
        本机跑的是 macOS beta / seed 版本。

        Nix 是纯求值，看不到宿主机的系统版本，所以只能声明不能探测。
        在机器上跑 `just check-beta` 可以知道是哪种。

        seed 版本上 Mac App Store 的 mas 安装不可靠，所以打开这个开关
        会把 masApps 整个从生成的 Brewfile 里拿掉。
      '';
    };

    taps = mkOption {
      type = types.listOf (types.either types.str (types.attrsOf types.anything));
      default = [];
      description = ''
        要加的 tap。

        Homebrew 6.0 起 HOMEBREW_REQUIRE_TAP_TRUST 默认打开，非官方 tap
        必须先被信任才能在 activation 时加载它的 formula/cask。写成
        `{ name = "..."; trusted = true; }` 会在 Brewfile 里生成
        `trusted: true`，brew bundle 在 fetch 之前就会应用，
        新机器上不用手动跑 `brew trust`。
      '';
    };

    brews = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "命令行 formula。";
    };

    casks = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "GUI 应用 cask。";
    };

    masApps = mkOption {
      type = types.attrsOf types.int;
      default = {};
      description = ''
        Mac App Store 应用，键是显示名，值是 App ID。
        需要先登录 Apple ID（`mas signin your@email.com`）。
        macosBeta = true 时整个忽略。
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    homebrew = {
      enable = true;

      onActivation = {
        autoUpdate = true;
        # 没在上面声明过的 Homebrew 包会在下次 switch 时被卸载。
        # 手动 `brew install` 装的东西是临时的：要么声明，要么丢。
        cleanup = "zap";
        extraFlags = ["--force-cleanup"];
      };

      inherit (cfg) taps brews casks;

      masApps = lib.optionalAttrs (!cfg.macosBeta) cfg.masApps;
    };
  };
}
