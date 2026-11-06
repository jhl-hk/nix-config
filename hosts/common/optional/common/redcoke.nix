{
  config,
  inputs,
  lib,
  ...
}:
#############################################################
#
#  API key for llm.redcoke.dev
#
#  Decryption only. The consumer is omp's redcoke provider in
#  home/jhl/common/optional/ai/omp.nix, which exports the key in zsh.
#
#  WARNING: /run/secrets/rd_llm/api_key is kept consistent **by hand** with
#     omp.redcokeKeyFile in home/jhl/common/optional/ai/omp.nix.
#
#  Filling in the ciphertext:
#    just sops-edit shared
#
#      rd_llm:
#          api_key: sk-xxxxxxxx
#
#############################################################
let
  sopsFile = "${inputs.nix-secrets}/secrets/shared.yaml";
in {
  assertions = [
    {
      assertion =
        builtins.pathExists sopsFile
        && lib.hasInfix "rd_llm:\n    api_key:" (builtins.readFile sopsFile);
      message = ''
        hosts/common/optional/common/redcoke.nix is imported, but
        secrets/shared.yaml has no rd_llm.api_key yet.

          just sops-edit shared

            rd_llm:
                api_key: sk-xxxxxxxx

        Then cd ../nix-secrets && git add -A && git commit && git push
        and back here run just update-nix-secrets.
      '';
    }
  ];

  sops.secrets."rd_llm/api_key" = {
    inherit sopsFile;
    owner = config.hostSpec.username;
    mode = "0400";
  };
}
