{
  config,
  inputs,
  lib,
  ...
}:
#############################################################
#
#  OpenClaw -- self-hosted multi-channel AI gateway
#
#  A cherry-picked optional: only jhlsMacBookAir runs it. The CLI, not the
#  cask -- `openclaw-cli` is the same 2026.7.1 release packaged from the
#  `openclaw` npm tarball, and it carries a bottle, so it never trips the
#  "Xcode too outdated" gate that unbottled formulae hit on a seed macOS.
#
#  `node` is a dependency and is already in the fleet-wide brews list, so
#  there is nothing extra to declare here.
#
#  -- Its configuration is deliberately NOT managed by home.file -----------
#
#  OpenClaw keeps state in ~/.openclaw and reads ~/.openclaw/openclaw.json.
#  Upstream is explicit that the file must be a **regular file**:
#
#    "OpenClaw-owned writes replace it atomically (rename onto the path), so
#     a symlinked openclaw.json gets its target replaced rather than written
#     through - avoid symlinked config layouts."
#
#  home.file produces exactly such a symlink, so managing that path the way
#  skills are managed would be silently destructive. This is the same trap
#  home/jhl/common/core/claude.nix documents for settings.json, and it takes
#  the same answer: merge keys in at activation time and leave the file
#  otherwise alone.
#
#  Precedence for anything secret, highest first:
#    process env  ->  ./.env  ->  ~/.openclaw/.env  ->  openclaw.json `env`
#  so a gateway token belongs in the environment or in ~/.openclaw/.env via
#  sops.templates, never in the JSON. OPENCLAW_GATEWAY_TOKEN is only required
#  when the gateway binds beyond loopback; left unset, OpenClaw generates one
#  on first start.
#
#############################################################
#  -- Secrets ------------------------------------------------------------
#
#  Both credentials are delivered through ~/.openclaw/.env rather than the
#  JSON, because env beats the config file in OpenClaw's own precedence order
#  and because the JSON is a file OpenClaw rewrites. Telegram would also take
#  a `tokenFile`, but OpenAI has no equivalent -- one mechanism for both is
#  worth more than using each channel's favourite.
#
#  Unlike openclaw.json, .env is only ever *read* by OpenClaw, so the symlink
#  sops.templates plants at that path is safe here.
#
#  Filling in the ciphertext:
#    just sops-edit shared
#
#      openai:
#          api_key: sk-xxxxxxxx
#      openclaw:
#          telegram_bot_token: "123456:ABCDEF..."
#
#    Telegram tokens contain a colon, so quote them or the YAML parses the
#    value as a nested mapping.
#
#############################################################
let
  sopsFile = "${inputs.nix-secrets}/secrets/shared.yaml";
  user = config.hostSpec.username;
in {
  darwinHomebrew = {
    # imsg is the iMessage bridge OpenClaw speaks JSON-RPC to over stdio.
    # BlueBubbles support was removed upstream; imsg is the only path now.
    taps = [
      {
        name = "steipete/tap";
        trusted = true;
      }
    ];

    brews = [
      "openclaw-cli"
      "imsg"
    ];
  };

  # Same eval-time pre-flight as llm.nix and wakatime.nix: sops leaves key
  # names in cleartext, so a substring search turns "not filled in yet" from
  # an opaque activation failure into an actionable message.
  assertions = [
    {
      assertion =
        builtins.pathExists sopsFile
        && lib.hasInfix "telegram_bot_token:" (builtins.readFile sopsFile)
        # Matched with its parent and its indentation, not as a bare
        # substring: `api_key:` on its own is already satisfied by the llm and
        # wakatime sections, so a plain hasInfix would pass while
        # openai/api_key does not exist. sops writes nested keys at four
        # spaces, which is what makes this exact form reliable.
        && lib.hasInfix "openai:\n    api_key:" (builtins.readFile sopsFile);
      message = ''
        hosts/common/optional/darwin/openclaw.nix is imported, but
        secrets/shared.yaml has no openclaw.telegram_bot_token yet.

          just sops-edit shared

            openai:
                api_key: sk-xxxxxxxx
            openclaw:
                telegram_bot_token: "123456:ABCDEF..."

        Quote the Telegram token -- it contains a colon.

        Then cd ../nix-secrets && git add -A && git commit && git push
        and back here run just update-nix-secrets.

        Bot token comes from @BotFather; the OpenAI key from
        https://platform.openai.com/api-keys
      '';
    }
  ];

  sops.secrets."openai/api_key" = {
    inherit sopsFile;
    owner = user;
    mode = "0400";
  };

  sops.secrets."openclaw/telegram_bot_token" = {
    inherit sopsFile;
    owner = user;
    mode = "0400";
  };

  sops.templates."openclaw-env" = {
    content = ''
      OPENAI_API_KEY=${config.sops.placeholder."openai/api_key"}
      JIANYUELAB_API_KEY=${config.sops.placeholder."llm/api_key"}
      JIANYUELAB_FALLBACK_API_KEY=${config.sops.placeholder."llm_api/api_key"}
      TELEGRAM_BOT_TOKEN=${config.sops.placeholder."openclaw/telegram_bot_token"}
    '';
    owner = user;
    mode = "0600";
    path = "${config.hostSpec.home}/.openclaw/.env";
  };
}
