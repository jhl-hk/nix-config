{hostSpec, ...}:
#############################################################
#
#  nh -- the nix-darwin/home-manager helper CLI
#
#  scripts/rebuild.sh uses it whenever it is on PATH: same activation as
#  darwin-rebuild, but the build runs under nix-output-monitor and the switch
#  ends with a package diff of what actually changed.
#
#  `flake` only sets NH_FLAKE, which is what makes a bare `nh darwin switch`
#  work from any directory. It is a plain string on purpose -- a path literal
#  would copy this whole repo into the store and pin nh to that snapshot.
#  scripts/rebuild.sh passes `.` explicitly, so it does not depend on this.
#
#  clean/ is deliberately left off: it is a systemd timer, which does not exist
#  on Darwin. `just clean` covers garbage collection here.
#
#############################################################
{
  programs.nh = {
    enable = true;
    flake = "${hostSpec.home}/Documents/nix-src/nix-config";
  };
}
