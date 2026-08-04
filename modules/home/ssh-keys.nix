{lib, ...}:
#############################################################
#
#  SSH 密钥选择
#
#  哪台机器用哪把私钥，是 per-host 的事实，不该写成
#  `if hostname == "..."` 的条件判断。声明成选项之后，
#  host 文件里一行 `sshKeys.primary = "...";` 就够了。
#
#  消费者：home/jhl/common/core/{ssh,git}.nix
#
#############################################################
{
  options.sshKeys = {
    primary = lib.mkOption {
      type = lib.types.str;
      default = "id_ed25519_sk_rk";
      description = ''
        ~/.ssh 下主私钥的文件名（不含路径）。
        同时用作 git 的 ssh 签名密钥（会自动加 .pub）。

        默认是常驻式 sk 密钥；插着 YubiKey 5C Nano 的机器覆盖成 id_ykmini。
      '';
    };

    extra = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = ["id_yk5c"];
      description = "额外挂进 ssh-agent / IdentityFile 的密钥文件名。";
    };
  };
}
