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
#  fj: the user-level counterpart of hosts/common/optional/nixos/forgejo.nix.
#  The forgejo-login user service seeds the fj login if it is missing.
#  The token still lives under tea.token. To rotate it:
#    fj -H git.jyl.as auth logout
#    systemctl --user restart forgejo-login
#
#  Do not import on a Mac: the system lane already provides these secrets.
#
#############################################################
let
  sopsFile = "${inputs.nix-secrets}/secrets/shared.yaml";
  secret = name: config.sops.secrets.${name}.path;
  forgejoHost = "git.jyl.as";
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
      # Counterpart of hosts/common/core/darwin/ssh-shared-key.nix.
      "ssh/id_shared" = {
        mode = "0400";
        path = "${config.home.homeDirectory}/.ssh/id_shared";
      };
    };
  };

  llm.apiKeyFile = lib.mkForce (secret "llm/api_key");
  llm.providers.JianyueLab.apiKeyFile = lib.mkForce (secret "llm/api_key");
  cloudflare.apiTokenFile = lib.mkForce (secret "cloudflare/api_token");
  wakatime.apiKeyFile = lib.mkForce (secret "wakatime/api_key");

  home.packages = [pkgs.forgejo-cli];

  systemd.user.services.forgejo-login = {
    Unit = {
      Description = "Seed the fj login for ${forgejoHost}";
      After = ["sops-nix.service"];
      Requires = ["sops-nix.service"];
    };
    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = toString (pkgs.writeShellScript "forgejo-login" ''
        export PATH=${lib.makeBinPath [pkgs.forgejo-cli pkgs.gnugrep]}:$PATH
        if fj auth list | grep -qF "${forgejoHost}"; then
          exit 0
        fi
        fj -H "${forgejoHost}" auth add-token < ${secret "tea/token"}
      '');
    };
    Install.WantedBy = ["default.target"];
  };
}
