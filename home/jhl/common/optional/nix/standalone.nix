{pkgs, ...}:
#############################################################
#
#  Nix settings for a machine whose distro owns /etc/nix
#
#  On the Macs, hosts/common/core/nix-settings.nix writes these through
#  nix-darwin, which generates /etc/nix/nix.conf. A standalone home-manager
#  machine has no system lane, and /etc/nix/nix.conf belongs to the distro's
#  nix package (pacman's, here) -- editing it is both root-owned and outside
#  this repo. So the same settings go into ~/.config/nix/nix.conf instead,
#  which nix reads *after* /etc/nix/nix.conf and which therefore wins.
#
#  That precedence is the reason scripts/rebuild.sh warns against this file on
#  Darwin: there it would silently outrank the nix.conf nix-darwin generates.
#  Here it is the only writable layer, which is exactly why it is opt-in per
#  host rather than part of core.
#
#  -- Chicken and egg ----------------------------------------------------
#
#  Enabling flakes is what lets you build this flake, and this file is what
#  enables flakes. The first activation on a new machine therefore needs them
#  passed on the command line:
#
#    nix --extra-experimental-features "nix-command flakes" \
#        build .#homeConfigurations."<user>@<host>".activationPackage
#
#  scripts/rebuild.sh does that automatically -- see its bootstrap branch.
#
#  -- What is deliberately not here --------------------------------------
#
#  substituters / trusted-public-keys. The flake declares them in nixConfig,
#  and nix refuses them from an untrusted user with
#
#    warning: ignoring untrusted flake configuration setting 'substituters'
#
#  A user-level nix.conf does not help: with a nix daemon, substituters are the
#  daemon's business, so the fix is `trusted-users = <user>` in the root-owned
#  /etc/nix/nix.conf. That is a system change on a system this repo does not
#  manage, so it stays a documented manual step rather than a silent no-op here.
#
#############################################################
{
  nix = {
    # Only used to validate the generated file (nix.checkConfig runs
    # `nix show-config` against it at build time). home-manager does not put it
    # on PATH, so the distro's own nix keeps serving -- which is what we want,
    # since it is the one paired with the running nix-daemon.
    package = pkgs.nix;

    settings.experimental-features = ["nix-command" "flakes"];
  };
}
