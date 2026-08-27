{
  config,
  lib,
  pkgs,
  ...
}:
#############################################################
#
#  OpenClaw -- the non-secret half of ~/.openclaw/openclaw.json
#
#  The package and both credentials come from
#  hosts/common/optional/darwin/openclaw.nix; this file only states the
#  settings that are safe in cleartext. Import it from the same machines that
#  import that one -- a config without the brew is inert, and the brew without
#  this is an unconfigured gateway.
#
#  -- Why this is an activation script and not home.file ------------------
#
#  Upstream, in docs/gateway/configuration.md:
#
#    "The active config path must be a regular file. OpenClaw-owned writes
#     replace it atomically (rename onto the path), so a symlinked
#     openclaw.json gets its target replaced rather than written through -
#     avoid symlinked config layouts."
#
#  home.file produces exactly such a symlink. `openclaw onboard`, `openclaw
#  configure`, `models set`, pairing approvals and the Control UI all write
#  this file, so nix has to be a co-author, not the owner -- the same split
#  home/jhl/common/core/claude.nix lives with for settings.json.
#
#  The merge is additive: keys stated here are asserted on every switch,
#  everything else in the file is left untouched. Removing a key here does
#  not remove it from the file.
#
#  -- Config is JSON5 -----------------------------------------------------
#
#  Comments and trailing commas are legal in openclaw.json, and jq cannot
#  parse either. If OpenClaw or you ever writes a commented config, the guard
#  below skips the merge with a warning rather than replacing the file with
#  jq's error output. Plain JSON is valid JSON5, so what nix writes stays
#  readable to OpenClaw either way.
#
#############################################################
let
  configPath = "${config.home.homeDirectory}/.openclaw/openclaw.json";

  # Model ref is provider/model. openai/gpt-5.6-sol is what a fresh OpenAI
  # API-key setup selects upstream; the bare openai/gpt-5.6 alias resolves to
  # the same model. Change it with `openclaw models set <provider/model>` and
  # this merge will assert it back on the next switch -- so change it here.
  settings = {
    agents.defaults = {
      workspace = "${config.home.homeDirectory}/.openclaw/workspace";
      model.primary = "openai/gpt-5.6-sol";
    };

    channels.telegram = {
      enabled = true;

      # The bot token is deliberately absent: it arrives as TELEGRAM_BOT_TOKEN
      # from ~/.openclaw/.env, rendered by sops. Writing it here would put a
      # live credential in a world-readable nix store path.
      #
      # pairing means a first-time DM has to be approved by hand:
      #   openclaw pairing list telegram
      #   openclaw pairing approve telegram <CODE>
      dmPolicy = "pairing";

      # Without this the bot answers every message in a group it is in.
      groups."*".requireMention = true;
    };
  };
in {
  home.activation.openclawConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
    config_path="${configPath}"

    # home-manager marks DRY_RUN_CMD deprecated and gates on DRY_RUN itself.
    # Prefixing would also be wrong here: $DRY_RUN_CMD neutralises the command
    # but never the redirection, so `$DRY_RUN_CMD echo '{}' > "$f"` writes the
    # literal text `echo {}` into the file on a dry run. Gate the whole block.
    if [[ -v DRY_RUN ]]; then
      echo "openclaw.nix: would merge config keys into $config_path"
    else
      mkdir -p "$(dirname "$config_path")"
      [ -s "$config_path" ] || echo '{}' > "$config_path"

      if ! ${pkgs.jq}/bin/jq -e . "$config_path" >/dev/null 2>&1; then
        echo "openclaw.nix: $config_path is not plain JSON (JSON5 comments?), skipping merge" >&2
      elif ${pkgs.jq}/bin/jq \
        --argjson s ${lib.escapeShellArg (builtins.toJSON settings)} \
        '. * $s' "$config_path" > "$config_path.nix-tmp"; then
        mv "$config_path.nix-tmp" "$config_path"
      else
        rm -f "$config_path.nix-tmp"
        echo "openclaw.nix: jq merge failed, left $config_path untouched" >&2
      fi
    fi
  '';
}
