{
  config,
  inputs,
  lib,
  ...
}:
#############################################################
#
#  ~/.npmrc -- @jianyuelab private GitHub Packages
#
#  The first real secret consumer, used to prove the sops pipeline works.
#
#  Uses sops.templates rather than sops.secrets.<x>.path directly: the token is
#  only one substring of the .npmrc format, and templates substitute the
#  placeholder at activation time before writing the file, whereas secrets.path
#  can only hand back the bare value.
#
#  WARNING: what lands at `path` is a **symlink** -> /run/secrets/rendered/npmrc,
#     not a file written in place (verified in practice). Three consequences:
#       - Reading is fine, npm follows the symlink; owner/mode apply to the
#         target (0600 jhl)
#       - /run is volatile and rebuilt after reboot by a launchd daemon; until
#         that finishes this is a dangling symlink
#       - **Stop using `npm login` / `npm config set`** -- those write through
#         the symlink, so the change lands in /run/secrets/rendered/ and is
#         wiped by the next activation. To change the token, change shared.yaml.
#
#  -- Turning it on takes three steps ------------------------------------
#  1) Create the ciphertext in nix-secrets (only you can do this step):
#
#       cd ../nix-secrets
#       nix shell nixpkgs#sops nixpkgs#age
#       export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
#       sops secrets/shared.yaml
#
#     Contents:
#
#       npm:
#           jianyuelab_token: ghp_xxxxxxxxxxxx
#
#     Then git add/commit/push, and back in nix-config run
#     `just update-nix-secrets`
#
#  2) Add it to the imports of each machine that needs it, in
#     hosts/darwin/<Host>/default.nix:
#       "hosts/common/optional/darwin/npmrc.nix"
#
#  3) just rebuild, then **confirm by hand** that decryption actually worked:
#       grep -q '^//npm.pkg.github.com/:_authToken=ghp' ~/.npmrc && echo OK
#     (on Darwin a sops failure is not reported; it just leaves the file
#     un-substituted)
#
#############################################################
let
  sopsFile = "${inputs.nix-secrets}/secrets/shared.yaml";
  user = config.hostSpec.username;
in {
  assertions = [
    {
      assertion =
        builtins.pathExists sopsFile
        && lib.hasInfix "npm:\n    jianyuelab_token:" (builtins.readFile sopsFile);
      message = ''
        hosts/common/optional/darwin/npmrc.nix needs npm.jianyuelab_token in
        secrets/shared.yaml.

          just sops-edit shared

            npm:
                jianyuelab_token: ghp_xxxxxxxxxxxx
      '';
    }
  ];

  sops.secrets."npm/jianyuelab_token" = {
    inherit sopsFile;
    owner = user;
    mode = "0400";
  };

  sops.templates."npmrc" = {
    content = ''
      @jianyuelab:registry=https://npm.pkg.github.com
      //npm.pkg.github.com/:_authToken=${config.sops.placeholder."npm/jianyuelab_token"}
    '';
    owner = user;
    mode = "0600";
    path = "${config.hostSpec.home}/.npmrc";
  };
}
