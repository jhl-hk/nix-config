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

  # Everything routes through the JianyueLab gateways; there is no direct
  # OpenAI provider. That also retires the agentRuntime pin that used to be
  # needed here -- OpenAI on its official endpoint defaults to the Codex
  # harness, but nothing addresses that endpoint any more.
  #
  # Change the model with `openclaw models set <provider/model>` and the merge
  # asserts it back on the next switch -- so change it here instead.
  settings = {
    agents.defaults = {
      # AGENTS.md is a read-only symlink from nix (see home.file below), so
      # the seeding pass must not try to create or rewrite it.
      skipBootstrap = true;

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
      # -- One gateway only, and that is forced ------------------------------
      #
      # OpenClaw ignores `apiKey.id`. Proven on jhlsMacBookAir, not inferred:
      # pointing a local echo server at a provider showed it sending a key of
      # 51 bytes / sha1 4410c65e, which is the llm-api key's value and not the
      # JIANYUELAB_API_KEY the config named. Then setting the *working*
      # provider's id to the key that is wrong for its own endpoint left it
      # working -- so the field is not read at all. One key goes to every
      # provider.
      #
      # Ruled out along the way, each by inspection on that machine: a
      # `secrets` block, a top-level `env` block, launchctl setenv, the
      # launchd plist's EnvironmentVariables, a duplicate provider definition,
      # a malformed .env (213 bytes, 3 lines, values are plain [A-Za-z0-9_-]),
      # and a stored auth profile (`openclaw models auth list` has only
      # openai:api-key). Giving each provider a distinct `apiKey.provider`
      # alias plus a matching `secrets.providers` entry changed nothing.
      #
      # Hence the shape of this file: OpenClaw can reach exactly one gateway,
      # so llm-api is gone from it entirely -- provider, allowlist entry and
      # fallbacks. The sops template in
      # hosts/common/optional/darwin/openclaw.nix stops rendering
      # JIANYUELAB_FALLBACK_API_KEY for the same reason: one key in the
      # environment is one key it can pick wrong.
      #
      # What this costs, stated plainly:
      #
      #   * No cross-gateway failover. It never worked anyway -- OpenClaw's
      #     failover decision for an auth error is `surface_error`, not
      #     `fallback_model`, so an llm-api fallback could not have rescued a
      #     401 on the primary.
      #   * The 900s lane is gone with its provider. That existed only for
      #     Ornith-1.5-35B-A3B, which the gateway has since retired: absent
      #     from /v1/models, and a call returns 502.
      #
      # Fallbacks stay inside this one provider, which still buys something
      # for 5xx and timeouts even though it cannot help with auth.
      model = {
        primary = "jianyuelab/qwen-flashnext";
        fallbacks = [
          "jianyuelab/gpt-5.6-luna"
        ];
      };

      # Override allowlist. Without it `--model` is refused with "not allowed
      # for agent" and no hint as to which setting is refusing -- the schema
      # calls this field a "Configured model catalog and allowlist", and it
      # takes provider/* wildcards.
      models = {
        "jianyuelab/*" = {};
      };
    };

    # One provider, one gateway. llm-api used to sit beside this as a second
    # provider and a failover target; see the comment above `model` for the
    # measurement that removed it.
    #
    # The model list comes from what `just llm-models` refreshes for this
    # endpoint. llm/models-api.json is still generated by that command and is
    # still read by other consumers -- it is simply no longer read here.
    models.providers = {
      jianyuelab = {
        baseUrl = "https://llm.jianyuelab.net/v1";
        api = "openai-completions";
        apiKey = {
          source = "env";
          provider = "default";
          id = "JIANYUELAB_API_KEY";
        };

        # Ornith-1.5-35B-A3B measured 77s to first reply on this gateway --
        # a 35B MoE is simply slow to start, not broken, and the default
        # idle timeout cut it off mid-run.
        #
        # 240 and not higher on purpose: Telegram's polling handler gives up
        # at 300s (observed: "handler timed out after 300.04s"), so a model
        # allowed past that would take the whole lane down with it rather
        # than failing one turn.
        #
        # This is the only ceiling that exists. The timeout error also names
        # agents.defaults.timeoutSeconds, but no agents.* timeout key is in
        # this version's config schema -- do not go looking for it.
        timeoutSeconds = 240;
        models =
          map (id: {
            inherit id;
            name = id;
          })
          (builtins.fromJSON (builtins.readFile ../../core/llm/models.json));
      };
    };

    # Web search. duckduckgo needs no key, which is the whole reason to pick
    # it here -- every other provider would mean another sops secret and
    # another line in the .env template for a capability that is incidental.
    tools.web.search.provider = "duckduckgo";

    # iMessage. The gateway spawns `imsg rpc` and speaks JSON-RPC over stdio --
    # no daemon, no port -- so this only has to say where the binary and the
    # Messages database are.
    #
    # cliPath is /opt/homebrew, not the /usr/local the upstream docs show:
    # that example is an Intel path and this is Apple Silicon.
    #
    # dmPolicy mirrors telegram. iMessage defaults to pairing upstream too,
    # but stating it keeps both channels reading the same way.
    #
    # WARNING: three things here are **not** declarable and have to be done
    #     once, interactively, on the Air itself -- not over ssh:
    #
    #       1. Messages.app signed in with an Apple ID.
    #       2. Full Disk Access for the process context that runs the gateway
    #          (it reads chat.db).
    #       3. Automation permission for Messages.app (it sends through it).
    #
    #     Permissions are granted per process context, and upstream is
    #     explicit that an ssh context does not work: sends fail with
    #     AppleEvents -1743 because macOS records the grant against
    #     /usr/libexec/sshd-keygen-wrapper, which System Settings offers no
    #     toggle for. The gateway already runs as a LaunchAgent in the user's
    #     gui session, which is a supported context -- but the grant still has
    #     to be triggered from a local session, e.g. `imsg chats --limit 1`.
    #
    #     Advanced actions (react, edit, unsend, threaded reply, effects,
    #     polls, group ops) additionally need SIP disabled. Plain send and
    #     receive do not, and that is what this config is scoped to.
    channels.imessage = {
      enabled = true;
      cliPath = "/opt/homebrew/bin/imsg";
      dbPath = "${config.home.homeDirectory}/Library/Messages/chat.db";
      dmPolicy = "pairing";
    };

    # Abandoned in favour of iMessage. The secret and the .env line stay so
    # that flipping this back is one word, not another sops edit.
    channels.telegram = {
      enabled = false;

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

  # AGENTS.md -- the workspace file OpenClaw loads at the start of every
  # session (docs/concepts/agent-workspace.md: "Operating instructions for the
  # agent ... Good place for rules").
  #
  # It exists because iMessage cannot render anything. Unlike whatsapp and
  # zalo, channels.imessage has no markdown or chunkMode option -- the schema
  # simply does not offer one -- so asterisks, fences and pipe tables arrive as
  # literal characters in the bubble. The fix is to stop the model emitting
  # them, not to post-process.
  #
  # WARNING: home.file is a read-only store symlink, so the agent cannot edit
  #     its own AGENTS.md any more. That is why skipBootstrap is set below:
  #     without it OpenClaw tries to seed this file when missing, and the
  #     bootstrap ritual would fight the symlink. Change the rules here and
  #     rebuild. Same trade ./wakatime.nix takes for ~/.wakatime.cfg.
  home.file."Documents/AGENTS.md".text = ''
    # Operating instructions

    ## Output format

    Replies reach the user over **iMessage**, which renders no markup at all.
    Write plain text.

    - No `**bold**`, `_italic_`, `# headings`, or `> quotes` -- the characters
      show up verbatim.
    - No fenced code blocks or pipe tables. For code, indent it and keep it
      short; for tabular data, use one `key: value` per line.
    - No footnote or link syntax. Put a bare URL on its own line.
    - Keep paragraphs short. A phone bubble is narrow and there is no
      horizontal scrolling.

    Long answers are fine when the question needs one -- brevity is not the
    goal, legibility on a phone is.

    ## Workspace

    This workspace is ~/Documents, which holds real work rather than a
    scratch directory: nix-src/ is the machine configuration for three Macs.
    Read before writing, and prefer showing a diff over editing in place when
    a change is not obviously safe.
  '';
}
