{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
#############################################################
#
#  fj -- Forgejo CLI login for git.jyl.as
#
#  Darwin counterpart of hosts/common/optional/nixos/forgejo.nix.
#  The token is decrypted from shared.yaml under the tea.token key.
#  Activation then runs `fj auth add-token` as the user if the login is
#  missing.
#
#  fj owns its keys file and writes to it, so the file is not managed as a
#  symlink. Activation only seeds it.
#
#  An existing login is skipped. To rotate the token:
#    fj -H git.jyl.as auth logout
#    just rebuild
#
#############################################################
let
  sopsFile = "${inputs.nix-secrets}/secrets/shared.yaml";
  user = config.hostSpec.username;
  host = "git.jyl.as";
  fj = lib.getExe' pkgs.forgejo-cli "fj";
in {
  assertions = [
    {
      assertion =
        builtins.pathExists sopsFile
        && lib.hasInfix "tea:\n    token:" (builtins.readFile sopsFile);
      message = ''
        hosts/common/core/darwin/forgejo.nix needs tea.token in
        secrets/shared.yaml.

          just sops-edit shared

            tea:
                token: xxxxxxxx
      '';
    }
  ];

  sops.secrets."tea/token" = {
    inherit sopsFile;
    owner = user;
    mode = "0400";
  };

  # sops-nix appends sops-install-secrets with mkAfter (1500); run after it.
  system.activationScripts.postActivation.text = lib.mkOrder 2000 ''
    if ! /usr/bin/sudo -u ${user} -H ${fj} auth list | /usr/bin/grep -qF "${host}"; then
      /usr/bin/sudo -u ${user} /bin/cat ${config.sops.secrets."tea/token".path} \
        | /usr/bin/sudo -u ${user} -H ${fj} -H "${host}" auth add-token \
        || echo "forgejo.nix: fj login for ${host} failed" >&2
    fi
  '';
}
