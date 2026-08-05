{
  config,
  inputs,
  lib,
  ...
}:
#############################################################
#
#  API key for the LLM gateway
#
#  Decryption only. Who consumes it and how the environment variable is
#  injected lives on the home side:
#    modules/home/llm.nix          the options and the overall design
#    home/jhl/common/core/llm.nix  provider instance + zsh/launchd injection
#
#  WARNING: the path /run/secrets/llm/api_key is kept consistent **by hand** in
#     two places: the sops.secrets key name here, and llm.apiKeyFile in
#     modules/home/llm.nix. System modules and home modules are two separate
#     option trees and cannot reference each other.
#
#  Filling in the ciphertext:
#    just sops-edit shared
#
#      llm:
#          api_key: sk-xxxxxxxx
#
#  mode 0400 with owner set to the user: Zed and opencode both run as the user
#  and could not read a root-only file.
#
#############################################################
let
  sopsFile = "${inputs.nix-secrets}/secrets/shared.yaml";
in {
  # The same cheap pre-flight check as modules/hosts/darwin/omni: sops encrypts
  # only values, key names stay in cleartext, and a text search is enough to
  # move "not filled in yet" from an opaque activation-time error to an
  # actionable message at evaluation time.
  assertions = [
    {
      assertion =
        builtins.pathExists sopsFile
        && lib.hasInfix "api_key:" (builtins.readFile sopsFile);
      message = ''
        hosts/common/optional/darwin/llm.nix is imported, but
        secrets/shared.yaml has no llm.api_key yet.

          just sops-edit shared

            llm:
                api_key: sk-xxxxxxxx

        Then cd ../nix-secrets && git add -A && git commit && git push
        and back here run just update-nix-secrets.

        Once that is in, run just llm-models to refresh the model list, then
        just rebuild.
      '';
    }
  ];

  sops.secrets."llm/api_key" = {
    inherit sopsFile;
    owner = config.hostSpec.username;
    mode = "0400";
  };
}
