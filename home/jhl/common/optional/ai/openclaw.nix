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
  openclawBin = "/opt/homebrew/bin/openclaw";
  completionDir = "${config.home.homeDirectory}/.zsh/completions";

  configPath = "${config.home.homeDirectory}/.openclaw/openclaw.json";

  # Model ref is provider/model. openai/gpt-5.6-sol is what a fresh OpenAI
  # API-key setup selects upstream; the bare openai/gpt-5.6 alias resolves to
  # the same model. Change it with `openclaw models set <provider/model>` and
  # this merge will assert it back on the next switch -- so change it here.
  settings = {
    agents.defaults = {
      # ~/Documents rather than the default ~/.openclaw/workspace: the agent
      # is meant to work on real files, and on this machine that is where they
      # are -- nix-config included.
      #
      # Worth being clear about what that widens. The workspace is the tree
      # the agent reads and writes, so anything under ~/Documents is in scope
      # for a Telegram message, which is why channels.telegram below keeps
      # dmPolicy = "pairing" and requires a mention in groups. Narrow this to
      # a subdirectory if that ever stops being the trade you want.
      workspace = "${config.home.homeDirectory}/Documents";
      model.primary = "openai/gpt-5.6-sol";
    };

    # The JianyueLab gateway, as an OpenAI-compatible provider.
    #
    # api = "openai-completions" picks the wire format; baseUrl carries the
    # /v1 because that is where this gateway serves it (verified: /v1/models
    # answers, /models does not). apiKey is written as an ${ENV} reference,
    # not a value -- OpenClaw resolves it at read time from the environment,
    # so the credential stays in ~/.openclaw/.env where sops renders it and
    # never lands in this world-readable config.
    #
    # models is intentionally absent: fill it once `just llm-models` has
    # populated home/jhl/common/core/llm/models-api.json, then set
    # agents.defaults.model.primary to one of those ids.
    models.providers.jianyuelab = {
      baseUrl = "https://llm-api.jianyuelab.net/v1";
      api = "openai-completions";
      apiKey = "\${JIANYUELAB_API_KEY}";
    };

    # Pin the runtime, or OpenAI silently routes through the Codex harness.
    # From the config schema's own description of agentRuntime.id:
    #
    #   "OpenAI on the official endpoint defaults to the Codex harness when
    #    omitted."
    #
    # That harness is a separate plugin, and a broken one here: it fails to
    # register with `Cannot read properties of undefined (reading
    # 'openSyncKeyedStore')`, after which a Telegram turn sits in
    # state=processing until the channel gives up 300s later. The symptom is
    # a bot that receives messages and never answers -- no error reaches the
    # user, and `openclaw status` only hints at it through a Runtime column
    # reading "OpenAI Codex".
    #
    # An API key wants the plain inference loop anyway; the Codex harness is
    # for ChatGPT/Codex OAuth setups.
    models.providers.openai.agentRuntime.id = "openclaw";

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

  # -- Shell completion ----------------------------------------------------
  #
  # `openclaw completion --install` refuses to run here: it wants to append to
  # ~/.zshrc, which home-manager owns as a read-only store symlink. Same trap
  # as home/jhl/common/core/claude.nix's settings.json, and it takes the same
  # shape of answer -- nix does the writing.
  #
  # --write-state drops four scripts into ~/.openclaw/completions/. The zsh one
  # is named openclaw.zsh but opens with `#compdef openclaw`, so it is an
  # fpath-style definition wearing the wrong filename: linked in as _openclaw
  # it is autoloaded lazily on first completion, whereas sourcing it would
  # parse 5400 lines in every new shell.
  #
  # Regenerated on each switch, so it tracks whatever version brew installed.
  home.activation.openclawCompletion = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [[ -v DRY_RUN ]]; then
      echo "openclaw.nix: would regenerate the zsh completion"
    elif [ -x ${openclawBin} ]; then
      ${openclawBin} completion --shell zsh --write-state >/dev/null 2>&1 || true
      mkdir -p "${completionDir}"
      ln -sf "${config.home.homeDirectory}/.openclaw/completions/openclaw.zsh" \
        "${completionDir}/_openclaw"
    else
      echo "openclaw.nix: ${openclawBin} is not installed, skipping completion" >&2
    fi
  '';

  # Order 550: fpath has to grow before compinit, and ../../core/zsh.nix
  # records compinit as order 570.
  programs.zsh.initContent = lib.mkOrder 550 ''
    fpath=("${completionDir}" $fpath)
  '';
}
