{lib, ...}:
#############################################################
#
#  CLOUDFLARE_API_TOKEN injection
#
#  wrangler reads this variable before it looks at ~/.wrangler, so exporting
#  it here means `wrangler login` never has to run and no OAuth state is left
#  on the machine. The ciphertext and the reasoning are in
#  hosts/common/optional/darwin/cloudflare.nix.
#
#  WARNING: /run/secrets/cloudflare/api_token is kept in sync **by hand** with
#     the sops.secrets key name on the system side. System and home are
#     separate option trees, so a rename there fails silently here -- wrangler
#     would simply fall back to asking you to log in.
#
#  Terminal only, like ./jyl-usage.nix and unlike ./llm.nix: wrangler is a
#  CLI, so there is no Dock-launched consumer to justify putting a second copy
#  of the token into the login-session-global environment via launchctl setenv.
#
#  The guard is the same one ./llm.nix documents: sops's launchd daemon
#  rebuilds /run/secrets only after boot, so an unreadable file is skipped
#  rather than exporting an empty string. An empty CLOUDFLARE_API_TOKEN is
#  worse than an absent one -- wrangler would treat itself as configured and
#  fail with an auth error instead of falling back.
#
#############################################################
let
  tokenFile = "/run/secrets/cloudflare/api_token";
in {
  programs.zsh.initContent = lib.mkAfter ''
    [ -r ${tokenFile} ] && export CLOUDFLARE_API_TOKEN="$(cat ${tokenFile})"
  '';
}
