{
  config,
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

  overlay = {
    # brew owns updates (`just update`, or `omp update`).
    startup.checkUpdate = false;

    # Reads the ~/.claude user root: CLAUDE.md, ~/.claude/skills, and the
    # Claude Code marketplace plugins (superpowers among them). Off by
    # default in omp.
    enabledProviders = ["claude"];

    # Choices made in the setup wizard, pinned so every machine matches.
    modelRoles.default = "anthropic/claude-opus-5-5";
    symbolPreset = "ascii";
    composer.shape = "claude";
    theme.dark = "dark-copper";
  };

  yaml = pkgs.formats.yaml {};
  overlayFile = ".omp/agent/nix.yml";
in {
  home.file =
    {
      ${overlayFile}.source = yaml.generate "omp-nix.yml" overlay;

      # Same reason as pi.nix's APPEND_SYSTEM.md: skills come from several
      # roots, and models build paths from names.
      ".omp/agent/APPEND_SYSTEM.md".text = ''
        Skills live in several directories. To load a skill, read the exact path listed for it. Never build a skill path from its name.
      '';
    }
    // lib.optionalAttrs (active != {}) {
      ".omp/agent/models.yml".source = yaml.generate "omp-models.yml" {
        providers = lib.mapAttrs (_: toProvider) active;
      };
    };

  home.sessionVariables.PI_CONFIG_FILES = "${config.home.homeDirectory}/${overlayFile}";
}
