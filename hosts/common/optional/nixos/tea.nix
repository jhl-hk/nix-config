{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
#############################################################
#
#  tea -- Gitea CLI login for git.jyl.as
#
#  The token is decrypted from shared.yaml. A oneshot service then runs
#  `tea logins add` as the user if the login is missing.
#
#  tea owns ~/.config/tea/config.yml and writes to it, so the file is not
#  managed as a symlink. The service only seeds it.
#
#  The service skips an existing login. To rotate the token:
#    tea logins delete "Jyl Git"
#    sudo systemctl restart tea-login
#
#  Filling in the ciphertext:
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
  loginName = "Jyl Git";
  url = "https://git.jyl.as";
in {
  assertions = [
    {
      assertion =
        builtins.pathExists sopsFile
        && lib.hasInfix "tea:\n    token:" (builtins.readFile sopsFile);
      message = ''
        hosts/common/optional/nixos/tea.nix is imported, but
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

  systemd.services.tea-login = {
    description = "Seed the tea login for ${url}";
    wantedBy = ["multi-user.target"];
    wants = ["network-online.target"];
    after = ["network-online.target"];
    path = [pkgs.tea pkgs.gnugrep];
    environment.HOME = config.hostSpec.home;
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = user;
    };
    script = ''
      if tea logins list --output simple | grep -qF "${loginName}"; then
        exit 0
      fi
      GITEA_SERVER_TOKEN="$(cat ${config.sops.secrets."tea/token".path})" \
        tea logins add --name "${loginName}" --url "${url}"
      tea logins default "${loginName}"
    '';
  };
}
