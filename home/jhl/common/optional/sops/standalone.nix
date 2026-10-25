{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
#############################################################
#
#  sops for a machine with no system lane
#
#  On the Macs, sops-nix runs as a system module and decrypts into
#  /run/secrets. A standalone home-manager machine has no system scope, so
#  the home-manager flavour of sops-nix does the same job as the user: it
#  decrypts with ~/.config/sops/age/keys.txt into $XDG_RUNTIME_DIR and links
#  the results under ~/.config/sops-nix/secrets/.
#
#  Consumers in home/jhl/common/core still default to /run/secrets paths,
#  which never exist here. The key file options are repointed below with
#  mkForce; anything added later that reads /run/secrets needs the same.
#
#  tea: the user-level counterpart of hosts/common/optional/nixos/tea.nix.
#  The tea-login user service seeds ~/.config/tea/config.yml if the login is
#  missing. To rotate the token:
#    tea logins delete "Jyl Git"
#    systemctl --user restart tea-login
#
#  Do not import on a Mac: the system lane already provides these secrets.
#
#############################################################
let
  sopsFile = "${inputs.nix-secrets}/secrets/shared.yaml";
  secret = name: config.sops.secrets.${name}.path;
  teaLogin = "Jyl Git";
  teaUrl = "https://git.jyl.as";
in {
  imports = [inputs.sops-nix.homeManagerModules.sops];

  sops = {
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
    defaultSopsFile = sopsFile;
    secrets = {
      "llm/api_key" = {};
      "cloudflare/api_token" = {};
      "wakatime/api_key" = {};
      "tea/token" = {};
    };
  };

  llm.apiKeyFile = lib.mkForce (secret "llm/api_key");
  llm.providers.JianyueLab.apiKeyFile = lib.mkForce (secret "llm/api_key");
  cloudflare.apiTokenFile = lib.mkForce (secret "cloudflare/api_token");
  wakatime.apiKeyFile = lib.mkForce (secret "wakatime/api_key");

  systemd.user.services.tea-login = {
    Unit = {
      Description = "Seed the tea login for ${teaUrl}";
      After = ["sops-nix.service"];
      Requires = ["sops-nix.service"];
    };
    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = toString (pkgs.writeShellScript "tea-login" ''
        export PATH=${lib.makeBinPath [pkgs.tea pkgs.gnugrep]}:$PATH
        if tea logins list --output simple | grep -qF "${teaLogin}"; then
          exit 0
        fi
        GITEA_SERVER_TOKEN="$(cat ${secret "tea/token"})" \
          tea logins add --name "${teaLogin}" --url "${teaUrl}"
        tea logins default "${teaLogin}"
      '');
    };
    Install.WantedBy = ["default.target"];
  };
}
