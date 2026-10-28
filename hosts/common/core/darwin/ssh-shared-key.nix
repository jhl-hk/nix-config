{
  config,
  inputs,
  lib,
  ...
}:
#############################################################
#
#  Shared SSH key (macOS)
#
#  One software ed25519 key shared by every machine. The private half is
#  ssh/id_shared in nix-secrets secrets/shared.yaml; the public half and the
#  IdentityFile wiring live in home/jhl/common/core/ssh.nix.
#
#  ~/.ssh/id_shared is a symlink to /run/secrets/ssh/id_shared.
#
#  The standalone lane declares the same secret in
#  home/jhl/common/optional/sops/standalone.nix.
#
#############################################################
let
  sopsFile = "${inputs.nix-secrets}/secrets/shared.yaml";
in {
  assertions = [
    {
      assertion = lib.hasInfix "id_shared:" (builtins.readFile sopsFile);
      message = "ssh/id_shared is missing from nix-secrets secrets/shared.yaml. Add it with `just sops-edit shared`, push nix-secrets, then run `just update-nix-secrets`.";
    }
  ];

  sops.secrets."ssh/id_shared" = {
    inherit sopsFile;
    owner = config.hostSpec.username;
    mode = "0400";
    path = "${config.hostSpec.home}/.ssh/id_shared";
  };
}
