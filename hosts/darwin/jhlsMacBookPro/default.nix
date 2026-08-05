{lib, ...}:
#############################################################
#
#  jhlsMacBookPro -- MacBook Pro
#
#  This machine has a YubiKey 5C Nano plugged in ("ykmini"), so its primary
#  SSH key differs -- see sshKeys.primary in home/jhl/jhlsMacBookPro.nix.
#
#############################################################
{
  imports = map lib.custom.relativeToRoot [
    "hosts/common/optional/darwin/steam.nix"
    "hosts/common/optional/darwin/llm.nix"
  ];

  hostSpec = {
    hostName = "jhlsMacBookPro";
    isMobile = true;
  };

  # sudo asks for a YubiKey touch first, falling back to Touch ID when the
  # key is absent or untouched. Registration steps are in the header of
  # modules/hosts/darwin/yubikey/default.nix.
  darwinYubikey.enable = true;

  # omniconfig + kubeconfig. Cluster admin happens only on this machine.
  darwinOmni.enable = true;
}
