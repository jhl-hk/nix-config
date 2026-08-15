{
  inputs,
  isDarwin,
  ...
}:
#############################################################
#
#  hostSpec population
#
#  The one place identity and topology data crosses from inputs.nix-secrets
#  into the option tree declared by modules/common/host-spec.nix. After this,
#  every module reads config.hostSpec.<x> and never touches inputs.nix-secrets
#  again -- that indirection is what makes secrets swappable, auditable, or
#  stubbable in one place.
#
#  It is a file of its own rather than a block in core/default.nix because two
#  lanes need it and only one of them has a system configuration:
#
#    system      hosts/common/core/default.nix imports it, as an ordinary
#                NixOS / nix-darwin module
#    standalone  flake.nix hands it to lib.custom.evalHostSpec, because a
#                home-manager-only machine has no system scope to run it in
#
#  So keep it a **pure hostSpec module**: no imports, no other options, nothing
#  that assumes a system module tree exists around it. Per-machine values go in
#  hosts/<lane>/<HostName>/, not here.
#
#############################################################
{
  hostSpec = {
    username = "jhl";
    handle = "jhl-hk";
    inherit isDarwin;

    inherit
      (inputs.nix-secrets)
      domain
      email
      userFullName
      sshAllowedSigners
      networking
      networkInfo
      serviceInfo
      ;
  };
}
