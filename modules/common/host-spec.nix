{
  config,
  lib,
  pkgs,
  ...
}:
#############################################################
#
#  hostSpec -- 数据总线
#
#  整个仓库唯一的跨平台数据通道。NixOS / nix-darwin / home-manager
#  三个作用域都会导入这个文件，所以同一份数据在哪儿都读得到。
#
#  谁往里写：
#    hosts/common/core/default.nix  -- 身份和拓扑，从 inputs.nix-secrets inherit
#    hosts/<platform>/<host>/       -- hostName 和这台机器的开关
#
#  谁读：所有模块，一律走 config.hostSpec.<x>。
#  模块里**不要**直接引用 inputs.nix-secrets —— 那层间接正是为了让
#  secrets 可以被替换、审计、或者整个 stub 掉。
#
#############################################################
let
  inherit (lib) mkOption types;

  # 布尔开关的简写，省掉一堆重复的 mkOption 样板。
  mkBoolOpt = default: description:
    mkOption {
      inherit default description;
      type = types.bool;
    };
in {
  options.hostSpec = mkOption {
    description = "本机的身份、拓扑与能力标记。";
    type = types.submodule {
      # 逃生舱：没声明的字符串键也能塞进来。下面每个显式声明的选项
      # 仍然保留各自更严格的类型，freeform 只兜住未声明的键。
      freeformType = types.attrsOf types.str;

      options = {
        # ---- 身份 ----
        username = mkOption {
          type = types.str;
          description = "主用户名。驱动 users.users.<u>、home-manager.users.<u> 和 home 的默认值。";
        };

        hostName = mkOption {
          type = types.str;
          description = "本机主机名。同时是 networkInfo.hosts.<hostName> 的索引键。";
        };

        handle = mkOption {
          type = types.str;
          description = "线上 handle（GitHub 用户名等），用于 ssh 注释和 dotfile 模板。";
        };

        userFullName = mkOption {
          type = types.str;
          description = "真实姓名，用于 git、GPG uid、邮件 From。";
        };

        domain = mkOption {
          type = types.str;
          description = "主域名，用于拼 FQDN。";
        };

        email = mkOption {
          type = types.attrsOf types.str;
          description = "邮箱地址集合。键由 nix-secrets 的 personal.nix 定义（user / gitHub / notifier ...）。";
        };

        home = mkOption {
          type = types.str;
          default =
            if pkgs.stdenv.isLinux
            then "/home/${config.hostSpec.username}"
            else "/Users/${config.hostSpec.username}";
          description = "用户家目录。默认在 submodule 内部惰性求值，所以这里用 pkgs.stdenv 是安全的。";
        };

        sshAllowedSigners = mkOption {
          type = types.listOf types.str;
          default = [];
          description = ''
            ~/.ssh/allowed_signers 的内容，每个元素一行。
            用于 git 的 ssh 签名校验。是公钥，不是密文，所以放在 nix-secrets 的明文半区。
          '';
        };

        # ---- 从 nix-secrets 来的自由形状数据 ----
        # 一律当成不透明的树，读叶子时用 `.<key> or { }` 兜底。
        work = mkOption {
          type = types.attrsOf types.anything;
          default = {};
          description = "雇主相关的配置包（代理、CA、内部仓库）。isWork = true 时必须非空。";
        };

        networking = mkOption {
          type = types.attrsOf types.anything;
          default = {};
          description = "通用网络参数（DNS、搜索域、端口表）。被 core 里的 inherit 覆盖。";
        };

        networkInfo = mkOption {
          type = types.attrsOf types.anything;
          default = {};
          description = "逐主机的网络事实，形状是 networkInfo.hosts.<HostName> = { ip4; gateway4; ... }。";
        };

        serviceInfo = mkOption {
          type = types.attrsOf types.anything;
          default = {};
          description = ''
            逐服务的端点数据。两种键混在一起：
              全局键   serviceInfo.<service>            任何主机都能用
              逐主机键 serviceInfo.<HostName>.<service> 只对那台机器生效
            读的时候按「逐主机 -> 全局 -> 空」三级兜底。
          '';
        };

        persistFolder = mkOption {
          type = types.str;
          default = "";
          description = "impermanence 的持久化根目录。impermanence 关着时才允许为空（有断言）。";
        };

        # ---- 能力标记 ----
        isMinimal = mkBoolOpt false "最小系统（安装器 / 救援盘），跳过 home-manager。";
        isMobile = mkBoolOpt false "笔记本形态，用于电源管理、休眠、背光。";
        isProduction = mkBoolOpt true "日常主力机（相对于实验沙箱），用于关掉吵闹的调试服务。";
        isServer = mkBoolOpt false "无头服务器，用于关掉桌面、登录管理器、音频。";
        isWork = mkBoolOpt false "工作机。为 true 时 work 必须非空（有断言）。";
        isDarwin = mkBoolOpt false ''
          本机是 macOS。

          在 pkgs.stdenv.isDarwin 会触发无限递归的地方读这个（典型是 sops、
          以及 home/<u>/common/core/default.nix 的平台选择）。

          注意 flake.nix 还通过 specialArgs 传了一个独立的顶层 isDarwin，
          那个是 flake 按调用的 builder 自动决定的，和这里的 hostSpec.isDarwin
          是两个绑定，值应该一致但来源不同。
        '';
        useYubikey = mkBoolOpt false "启用 YubiKey 相关配置（pam-u2f、gpg-agent ssh、udev）。";
        voiceCoding = mkBoolOpt false "启用语音编程栈（talon / cursorless）。";
        isAutoStyled = mkBoolOpt false "接入 stylix 统一配色。";
        useNeovimTerminal = mkBoolOpt false "用内嵌 nvim 终端替换终端启动器绑定。";
        useWindowManager = mkBoolOpt true "启用窗口管理器。服务器或纯 tty 机器设 false。";
        useAtticCache = mkBoolOpt true ''
          启用 attic 二进制缓存。

          全新装好的机器在路由通之前会卡在拉缓存上，第一次 rebuild 先设 false，
          等网络正常再打开。
        '';
        hdr = mkBoolOpt false "合成器启用 HDR。";
        loadUserAgeKey = mkBoolOpt false "除主机密钥外，额外加载用户作用域的 age key。";

        wifi = mkBoolOpt false "本机有无线网卡。";

        # ---- 显示 ----
        scaling = mkOption {
          type = types.str;
          default = "1";
          description = ''
            缩放倍率，存成字符串（例如 "1.25"）而不是浮点数，
            这样可以原样插进配置文件而不用重新加引号。
          '';
        };
      };
    };
  };

  config = let
    inherit (config.hostSpec) isWork work persistFolder;

    # home-manager 作用域里没有 `system` 命名空间，不 guard 会直接求值失败。
    isImpermanent = (config ? "system") && (config.system.impermanence.enable or false);
  in {
    assertions = [
      {
        assertion = !isWork || (isWork && work != {});
        message = "hostSpec.isWork = true 时必须同时给出 hostSpec.work。";
      }
      {
        assertion = !isImpermanent || (isImpermanent && persistFolder != "");
        message = "启用 impermanence 时必须设置 hostSpec.persistFolder。";
      }
    ];
  };
}
