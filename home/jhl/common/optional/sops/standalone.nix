{
  config,
  inputs,
  lib,
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
#  Do not import on a Mac: the system lane already provides these secrets.
#
#############################################################
let
  sopsFile = "${inputs.nix-secrets}/secrets/shared.yaml";
in {
  imports = [inputs.sops-nix.homeManagerModules.sops];

  sops = {
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
    defaultSopsFile = sopsFile;
    secrets."llm/api_key" = {};
  };

  llm.apiKeyFile = lib.mkForce config.sops.secrets."llm/api_key".path;
  llm.providers.JianyueLab.apiKeyFile = lib.mkForce config.sops.secrets."llm/api_key".path;
}
