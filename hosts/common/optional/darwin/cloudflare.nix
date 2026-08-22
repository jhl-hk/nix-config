{
  config,
  inputs,
  lib,
  ...
}:
#############################################################
#
#  API token for Cloudflare (wrangler, and anything else hitting the CF API)
#
#  Decryption only. The token is injected as CLOUDFLARE_API_TOKEN by
#  home/jhl/common/core/cloudflare.nix -- the same split llm.nix lives with,
#  and for the same reason: system modules and home modules are separate
#  option trees and cannot reference each other.
#
#  -- Why a token and not `wrangler login` -------------------------------
#
#  wrangler's OAuth flow writes credentials into ~/.wrangler, which is
#  unmanaged mutable state that expires, cannot be rebuilt from this repo, and
#  has to be redone on every machine. A token in sops is declarative, works
#  the same in a script as in a terminal, and is scoped: mint it with only the
#  permissions the work needs (for R2, "Workers R2 Storage:Edit" is enough).
#
#  Note what this token is NOT: R2's S3-compatible API takes an Access Key ID
#  and Secret Access Key, which are a *different* credential minted on the R2
#  page. rclone and awscli need those, not this. Add them as r2/access_key_id
#  and r2/secret_access_key when you want that path.
#
#  Filling in the ciphertext:
#    just sops-edit shared
#
#      cloudflare:
#          api_token: xxxxxxxx
#
#    Then cd ../nix-secrets && git add -A && git commit && git push,
#    and back here run just update-nix-secrets.
#
#  mode 0400 with owner set to the user: wrangler runs as the user.
#
#############################################################
let
  sopsFile = "${inputs.nix-secrets}/secrets/shared.yaml";
in {
  # Same eval-time pre-flight as llm.nix and wakatime.nix. It matches
  # "cloudflare:" rather than "api_token:", because sops leaves key names in
  # cleartext and the narrower string is the only one that proves *this*
  # secret exists rather than some other section's.
  assertions = [
    {
      assertion =
        builtins.pathExists sopsFile
        && lib.hasInfix "cloudflare:" (builtins.readFile sopsFile);
      message = ''
        hosts/common/optional/darwin/cloudflare.nix is imported, but
        secrets/shared.yaml has no cloudflare.api_token yet.

          just sops-edit shared

            cloudflare:
                api_token: xxxxxxxx

        Then cd ../nix-secrets && git add -A && git commit && git push
        and back here run just update-nix-secrets.

        Mint the token at
        https://dash.cloudflare.com/profile/api-tokens -- for R2 work the
        "Workers R2 Storage:Edit" permission is enough.
      '';
    }
  ];

  sops.secrets."cloudflare/api_token" = {
    inherit sopsFile;
    owner = config.hostSpec.username;
    mode = "0400";
  };
}
