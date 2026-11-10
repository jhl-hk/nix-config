{
  config,
  hostSpec,
  inputs,
  lib,
  pkgs,
  ...
}:
#############################################################
#
#  omp -- oh-my-pi (https://github.com/can1357/oh-my-pi), a pi fork
#
#  The binary is the can1357/tap/omp brew in
#  hosts/common/optional/darwin/dev-extras.nix on the Macs, and the distro
#  package on jhlsTokyoDesktop.
#
#  -- config.yml stays omp's ----------------------------------------------
#
#  omp writes ~/.omp/agent/config.yml itself (setup wizard, /settings,
#  `omp config set`), so it is not linked from the store. nix owns an overlay
#  instead, ~/.omp/agent/nix.yml, loaded through PI_CONFIG_FILES. Overlays rank
#  above config.yml, so a key set here cannot be changed from /settings.
#  Change it here and rebuild.
#
#  An overlay that is missing or invalid is a hard error at startup, and
#  PI_CONFIG_FILES only reaches shells started after a switch.
#
#  -- Providers -----------------------------------------------------------
#
#  ~/.omp/agent/models.yml is the fourth consumer of llm.providers, next to
#  pi.nix, opencode.nix and Zed. apiKey is an environment variable *name*:
#  omp looks it up and, if unset, sends the literal string. The variable is
#  exported by home/jhl/common/core/llm.nix.
#
#  redcoke (https://llm.redcoke.dev/v1) is omp-only and not in llm.providers.
#  It is a new-api gateway, so discovery type proxy reads /v1/models at
#  runtime and picks each model's wire from supported_endpoint_types. No model
#  list is generated. Its key is the rd_llm/api_key sops secret
#  (hosts/common/optional/common/redcoke.nix on the Macs,
#  home/jhl/common/optional/sops/standalone.nix on the standalone lane),
#  exported as REDCOKE_API_KEY by the zsh block below.
#
#############################################################
let
  active = lib.filterAttrs (_: p: p.models != []) config.llm.providers;

  # Same claims as pi.nix: every gateway model reasons, and the gateway
  # accepts exactly these efforts.
  toModel = p: id: {
    inherit id;
    reasoning = true;
    contextWindow = p.maxTokens;
    maxTokens = p.maxOutputTokens;
    thinking = {
      mode = "effort";
      efforts = ["low" "medium" "high" "xhigh" "max"];
    };
  };

  toProvider = p: {
    baseUrl = p.apiUrl;
    api = "openai-completions";
    apiKey = p.envVar;
    authHeader = true;
    # The gateway rejects role "developer"; see pi.nix.
    compat.supportsDeveloperRole = false;
    models = map (toModel p) p.models;
  };

  redcoke = {
    baseUrl = "https://llm.redcoke.dev/v1";
    apiKey = "REDCOKE_API_KEY";
    authHeader = true;
    disableStrictTools = true;
    discovery.type = "proxy";
  };

  overlay = {
    # brew / pacman own updates (`just update`, or `omp update`).
    startup.checkUpdate = false;
    update.auto = false;

    # Reads the ~/.claude user root: CLAUDE.md, ~/.claude/skills, and the
    # Claude Code marketplace plugins (superpowers among them). Off by
    # default in omp.
    enabledProviders = ["claude"];

    # Choices made in the setup wizard, pinned so every machine matches.
    modelRoles.default = "anthropic/claude-opus-5-5";
    defaultThinkingLevel = "auto";
    statusLine = {
      preset = "nerd";
      separator = "powerline";
      contextLine = "annotated";
      sessionAccent = true;
      showHookStatus = true;
    };

    # Fast mode on by default for OpenAI-family models, gateway gpt-* included:
    # sent as service_tier = "priority". `/fast` still toggles it per session.
    tier.openai = "priority";
    symbolPreset = "unicode";
    composer.shape = "claude";
    # Both slots pinned: omp picks theme.light on a light terminal background,
    # and its default ("light") would otherwise apply there.
    theme = {
      dark = "dark-copper";
      light = "dark-copper";
    };
  };

  yaml = pkgs.formats.yaml {};
  overlayFile = ".omp/agent/nix.yml";
in {
  options.omp.redcokeKeyFile = lib.mkOption {
    type = lib.types.str;
    default = "/run/secrets/rd_llm/api_key";
    description = "Decrypted llm.redcoke.dev API key.";
  };

  config = {
    home.file =
      {
        ${overlayFile}.source = yaml.generate "omp-nix.yml" overlay;

        # Same reason as pi.nix's APPEND_SYSTEM.md: skills come from several
        # roots, and models build paths from names.
        ".omp/agent/APPEND_SYSTEM.md".text = ''
          Skills live in several directories. To load a skill, read the exact path listed for it. Never build a skill path from its name.
        '';

        # jyl-memory's omp half (see ../../core/jyl-memory.nix). omp loads
        # hooks/post/*.ts and ignores the plugin's hooks/hooks.json, so the hook
        # is linked here rather than arriving with the Claude Code plugin. omp
        # resolves the symlink, so the hook finds scripts/run next to itself in
        # the store.
        ".omp/agent/hooks/post/jyl-memory.ts".source = "${inputs.jianyuelab-plugins}/plugins/jyl-memory/hooks/post/jyl-memory.ts";

        # WakaTime heartbeats (wakatime-omp, pinned input). omp auto-loads
        # extensions/*.ts. The extension takes the first wakatime-cli on PATH,
        # which is the one opencode.nix installs; that build must be new enough
        # to carry wakatime-cli's OMP transcript parser (pkg/ai/omp.go, absent
        # from 2.14.5). The key comes from ../../core/wakatime.nix.
        ".omp/agent/extensions/wakatime.ts".source = "${inputs.wakatime-omp}/src/extension.ts";

        ".omp/agent/models.yml".source = yaml.generate "omp-models.yml" {
          providers = lib.mapAttrs (_: toProvider) active // {inherit redcoke;};
        };
      }
      # NotchNotch's omp plugin (pinned input). Only the Macs run the app. The
      # extension posts turn ends; the manifest directory registers the plugin
      # with the app. The app, the agent plugin and the preferences are in
      # ../../core/darwin/notchnotch.nix.
      // lib.optionalAttrs hostSpec.isDarwin {
        ".omp/agent/extensions/notchnotch.ts".source = "${inputs.notchnotch}/plugins/omp/notchnotch.ts";
        "Library/Application Support/NotchNotch/Plugins/co.jianyuelab.notchnotch.omp".source = "${inputs.notchnotch}/plugins/omp";
      };

    # Unreadable file (not decrypted yet) leaves the variable unset.
    programs.zsh.initContent = ''
      [ -r ${config.omp.redcokeKeyFile} ] && export REDCOKE_API_KEY="$(cat ${config.omp.redcokeKeyFile})"
    '';

    home.sessionVariables.PI_CONFIG_FILES = "${config.home.homeDirectory}/${overlayFile}";
  };
}
