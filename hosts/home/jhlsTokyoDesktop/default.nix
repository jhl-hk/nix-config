{...}:
#############################################################
#
#  jhlsTokyoDesktop -- Linux desktop, managed by standalone home-manager
#
#  Not a system module. flake.nix feeds this file to lib.custom.evalHostSpec;
#  it may only set hostSpec.
#
#  hostName must match this directory name and home/jhl/${hostName}.nix.
#
#############################################################
{
  hostSpec = {
    hostName = "jhlsTokyoDesktop";
  };
}
