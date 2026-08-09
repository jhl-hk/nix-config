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

    # Bash + flyline. zsh stays the login shell; this only affects `bash`.
    # Needs hosts/common/optional/darwin/flyline.nix on the system side.
    ./common/optional/shell/flyline.nix
  ];

  # Only this machine has a YubiKey 5C Nano plugged in ("ykmini"); the others
  # use the resident sk key.
  sshKeys.primary = "id_ykmini";
}
