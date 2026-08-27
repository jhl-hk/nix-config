{...}:
#############################################################
#
#  home: jhl @ jhlsMacBookAir
#
#############################################################
{
  # No editors/: zed.nix and typora.nix configure casks that this machine no
  # longer installs, now that it declines desktop.nix. Both set package = null
  # so they would still evaluate -- they would just write dotfiles for
  # applications that are not there.
  imports = [
    ./common/core
    ./common/optional/ai/openclaw.nix
  ];
}
