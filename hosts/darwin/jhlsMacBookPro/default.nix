{lib, ...}:
#############################################################
#
#  jhlsMacBookPro -- MacBook Pro
#
#  这台机器插着 YubiKey 5C Nano（"ykmini"），主 SSH 密钥因此不同 ——
#  见 home/jhl/jhlsMacBookPro.nix 里的 sshKeys.primary。
#
#############################################################
{
  imports = map lib.custom.relativeToRoot [
    "hosts/common/optional/darwin/steam.nix"
  ];

  hostSpec = {
    hostName = "jhlsMacBookPro";
    isMobile = true;
  };
}
