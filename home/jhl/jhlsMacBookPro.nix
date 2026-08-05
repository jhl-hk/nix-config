{...}:
#############################################################
#
#  home: jhl @ jhlsMacBookPro
#
#  This machine's order ticket: core is the baseline wanted everywhere,
#  optional is what this machine additionally wants.
#
#############################################################
{
  imports = [
    ./common/core
    ./common/optional/editors/zed.nix
    ./common/optional/editors/typora.nix
  ];

  # Only this machine has a YubiKey 5C Nano plugged in ("ykmini"); the others
  # use the resident sk key.
  sshKeys.primary = "id_ykmini";
}
