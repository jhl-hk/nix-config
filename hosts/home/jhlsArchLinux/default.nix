{...}:
#############################################################
#
#  jhlsArchLinux -- Arch Linux, managed by standalone home-manager
#
#  Arch is not NixOS: nix sits on top of a distro that already owns the system,
#  so there is no system configuration to attach to and nothing here can set
#  NixOS or nix-darwin options. This file is **not** a system module -- flake.nix
#  feeds it to lib.custom.evalHostSpec, and the only thing it may contribute is
#  hostSpec.
#
#  Everything nix actually installs and writes on this machine lives in
#  home/jhl/jhlsArchLinux.nix.
#
#  hostName must match this directory name: flake.nix keys the configuration off
#  the directory, and home/jhl/${hostName}.nix is the home file it pairs with.
#
#############################################################
{
  hostSpec = {
    hostName = "jhlsArchLinux";
  };
}
