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
#  The token is decrypted from shared.yaml. A oneshot service then runs
#  `fj auth add-token` as the user if the login is missing.
#
#  fj owns its keys file and writes to it, so the file is not managed as a
#  symlink. The service only seeds it.
#
#  The service skips an existing login. To rotate the token:
#    fj -H git.jyl.as auth logout
#    sudo systemctl restart forgejo-login
#
#  The token still lives under the tea.token key. Filling in the ciphertext:
#    just sops-edit shared
#
#      tea:
#          token: xxxxxxxx
#
#  Token: git.jyl.as > Settings > Applications.
#
#############################################################
let
  sopsFile = "${inputs.nix-secrets}/secrets/shared.yaml";
  user = config.hostSpec.username;
  host = "git.jyl.as";
in {
  assertions = [
    {
      assertion =
        builtins.pathExists sopsFile
        && lib.hasInfix "tea:\n    token:" (builtins.readFile sopsFile);
      message = ''
        hosts/common/optional/nixos/forgejo.nix is imported, but
        secrets/shared.yaml has no tea.token yet.

          just sops-edit shared

            tea:
                token: xxxxxxxx

        Then cd ../nix-secrets && git add -A && git commit && git push
        and back here run just update-nix-secrets.
      '';
    }
  ];

  sops.secrets."tea/token" = {
    inherit sopsFile;
    owner = user;
    mode = "0400";
  };

  systemd.services.forgejo-login = {
    description = "Seed the fj login for ${host}";
    wantedBy = ["multi-user.target"];
    wants = ["network-online.target"];
    after = ["network-online.target"];
    path = [pkgs.forgejo-cli pkgs.gnugrep];
    environment.HOME = config.hostSpec.home;
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = user;
    };
    script = ''
      if fj auth list | grep -qF "${host}"; then
        exit 0
      fi
      fj -H "${host}" auth add-token < ${config.sops.secrets."tea/token".path}
    '';
  };
}
