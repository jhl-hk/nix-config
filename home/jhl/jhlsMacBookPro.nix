{...}:
#############################################################
#
#  home: jhl @ jhlsMacBookPro
#
#  这台机器的「点菜单」：core 是到处都要的基线，
#  optional 是这台机器额外要的。
#
#############################################################
{
  imports = [
    ./common/core
    ./common/optional/editors/zed.nix
    ./common/optional/editors/typora.nix
  ];

  # 只有这台插着 YubiKey 5C Nano（"ykmini"），其余机器用常驻 sk 密钥。
  sshKeys.primary = "id_ykmini";
}
