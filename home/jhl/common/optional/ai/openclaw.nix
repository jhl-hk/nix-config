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
      # provider/model. Points at the JianyueLab gateway declared below rather
      # than openai/*, so turns bill against the portal and land in its meter.
      # Ornith is only on that endpoint; llm.jianyuelab.net does not list it.
      model.primary = "jianyuelab/Ornith-1.5-35B-A3B";
    };

    # The JianyueLab gateway, as an OpenAI-compatible provider.
    #
    # api = "openai-completions" picks the wire format; baseUrl carries the
    # /v1 because that is where this gateway serves it (verified: /v1/models
    # answers, /models does not). apiKey is a secret reference rather than a
    # value, so the credential stays in ~/.openclaw/.env where sops renders it
    # and never lands in this world-readable config.
    #
    models.providers.jianyuelab = {
      baseUrl = "https://llm-api.jianyuelab.net/v1";
      api = "openai-completions";
      # A secret **reference**, not a value and not a "${VAR}" string. The
      # schema takes either a plain string or {source, provider, id}, and a
      # string is used verbatim -- writing "${JIANYUELAB_API_KEY}" sends those
      # 22 characters to the gateway as the bearer token, which answers 401.
      # Confirmed the hard way: the same key works from `just llm-models`.
      #
      # source = "env" resolves at request time from the gateway process
      # environment, which ~/.openclaw/.env populates and sops renders.
      apiKey = {
        source = "env";
        provider = "default";
        id = "JIANYUELAB_API_KEY";
      };

      # Catalogue read from the same file `just llm-models` refreshes for Zed
      # and opencode, so one command keeps all three harnesses current and
      # there is no second list to forget.
      #
      # Only id and name are stated. The schema also takes contextWindow,
      # maxTokens, reasoning and input, but guessing those per model is worse
      # than letting OpenClaw apply its own defaults -- a wrong contextWindow
      # truncates silently.
      models =
        map (id: {
          inherit id;
          name = id;
        })
        (builtins.fromJSON (builtins.readFile ../../core/llm/models-api.json));
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

    # Web search. duckduckgo needs no key, which is the whole reason to pick
    # it here -- every other provider would mean another sops secret and
    # another line in the .env template for a capability that is incidental.
    tools.web.search.provider = "duckduckgo";

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

  # -- Skills --------------------------------------------------------------
  #
  # OpenClaw discovers skills from its own managed directory and has no config
  # option for extra search paths -- the schema's only skills-and-path key is
  # skills.limits.maxSkillsLoadedPerSource. So the nine skills ./claude.nix
  # links into ~/.claude/skills are linked on again here.
  #
  # Symlinks rather than `openclaw skills install`: that command copies, and a
  # copy drifts the moment nix rebuilds. It also cannot read these anyway --
  # ~/.claude/skills/<name> is itself a symlink into the store, and the
  # installer fails with ERR_FS_CP_NON_DIR_TO_DIR on it.
  #
  # Pointing at ~/.claude/skills/<name> rather than at the store path is what
  # keeps this current: nix repoints that link on every switch and this one
  # follows, so a skill only has to be declared in ./claude.nix.
  #
  # Note the document skills (docx/pdf/pptx/xlsx) shell out to pandoc, qpdf
  # and poppler, which live in dev-extras.nix -- a file jhlsMacBookAir does
  # not import. They are listed here and inert there.
  home.activation.openclawSkills = lib.hm.dag.entryAfter ["linkGeneration"] ''
    if [[ -v DRY_RUN ]]; then
      echo "openclaw.nix: would relink skills into ~/.openclaw/skills"
    else
      src="${config.home.homeDirectory}/.claude/skills"
      dst="${config.home.homeDirectory}/.openclaw/skills"
      mkdir -p "$dst"
      for s in "$src"/*; do
        [ -e "$s" ] || continue
        ln -sfn "$s" "$dst/$(basename "$s")"
      done

      # Drop links whose target ./claude.nix no longer deploys, so removing a
      # skill there removes it here too. Only symlinks are touched; anything
      # installed into this directory by `openclaw skills install` is a real
      # directory and is left alone.
      for l in "$dst"/*; do
        [ -L "$l" ] || continue
        [ -e "$l" ] || rm -f "$l"
      done
    fi
  '';
}
