{
  config,
  lib,
  pkgs,
  ...
}:
#############################################################
#
#  pi -- terminal coding agent (https://pi.dev/docs/latest)
#
#  Third consumer of llm.providers, next to opencode.nix and the Zed block in
#  home/jhl/common/optional/editors/zed.nix. Two generated files:
#
#    ~/.pi/agent/models.json     the providers and their model lists
#    ~/.pi/agent/settings.json   defaults, skills, telemetry
#
#  The model list is entirely llm/models.json, which `just llm-models`
#  regenerates from /v1/models on every rebuild. Nothing about a model is
#  written by hand here, so adding or retiring one upstream reaches pi with no
#  edit to this file -- exactly the deal opencode and Zed already have.
#
#  -- Where the binary comes from ----------------------------------------
#
#  nixpkgs, unlike opencode (brew) and Claude Code (cask): there is no formula
#  and no cask, and upstream's install path is
#  `npm install -g @earendil-works/pi-coding-agent`, which would land outside
#  both package managers. pkgs.unstable because stable 26.05 carries 0.75.4
#  against unstable's 0.83.x -- pi ships several releases a week.
#
#  Because nix owns the binary, `pi update` cannot work (it would npm-install
#  over a read-only store path), so PI_SKIP_VERSION_CHECK silences the notice
#  that suggests it. Bump the version with `just update` instead.
#
#  -- pi does not use XDG -------------------------------------------------
#
#  Config lives under ~/.pi/agent unconditionally, so these are home.file
#  entries, not xdg.configFile.
#
#  -- Consequences of a read-only symlink ---------------------------------
#
#  The trade claude.nix and opencode.nix both record. home.file generates a
#  read-only symlink into the nix store, so `/settings` -- pi's in-TUI editor
#  for settings.json -- cannot save. Edit the settings set below instead.
#
#  Only settings.json is affected: the files pi writes on its own initiative
#  (auth.json from /login, trust.json from /trust, sessions) are deliberately
#  left unmanaged, and models.json is never written by pi at all -- it only
#  re-reads it, on every /model.
#
#  -- Where the key goes --------------------------------------------------
#
#  Nowhere near the nix store. models.json resolves "$VAR" from the
#  environment (pi's own value-resolution syntax, alongside "!command" and
#  literals), and the variable is exported into zsh by
#  home/jhl/common/core/llm.nix. pi is terminal-only, so the launchd half of
#  that file -- which exists because Zed can be started from the Dock -- has
#  nothing to do here.
#
#############################################################
let
  # Only wire up providers with a refreshed model list (see the models option
  # in modules/home/llm.nix)
  active = lib.filterAttrs (_: p: p.models != []) config.llm.providers;

  # Every model is described the same way, from llm/models.json alone -- no
  # hand-picked ids here, the way Zed's capabilities block is also uniform.
  # A model is in the file or it does not exist as far as pi is concerned.
  #
  # reasoning = true is a deliberate blanket claim: it is what makes pi offer
  # thinking levels and send reasoning_effort, and the gateway's catalog is
  # reasoning models (gpt-5.x, deepseek-v4). The failure mode if that ever
  # stops being true for one model is a 400 on the parameter, answered with
  # provider-level compat.supportsReasoningEffort = false below.
  #
  # llm.maxTokens is the context window (it is named after Zed's max_tokens);
  # pi keeps the two apart, so the names do not line up one-to-one.
  toModel = p: id: {
    inherit id;
    reasoning = true;
    contextWindow = p.maxTokens;
    maxTokens = p.maxOutputTokens;
  };

  # "$FOO" is pi's environment interpolation, so what lands in the store is the
  # variable name, never the key. Written as a concatenation on purpose: in a
  # nix string "$${p.envVar}" is not "$" followed by an interpolation, it is
  # the escape for a literal "$" followed by the literal text "{p.envVar}".
  toProvider = p: {
    baseUrl = p.apiUrl;
    api = "openai-completions";
    apiKey = "$" + p.envVar;

    # The gateway only accepts the classic OpenAI roles. pi sends the system
    # prompt as role "developer" for models it believes reason, which every
    # model here claims to be, and the first request comes back:
    #
    #   400 messages[0].role: unknown variant `developer`, expected one of
    #       `system`, `user`, `assistant`, `tool`, `latest_reminder`
    #
    # This is the switch pi documents for exactly that endpoint shape; with it
    # the prompt goes out as "system" again. Its sibling,
    # supportsReasoningEffort, stays on -- the gateway has not objected to that
    # parameter, and turning it off would give up thinking levels.
    compat.supportsDeveloperRole = false;

    models = map (toModel p) p.models;
  };

  models = {
    providers = lib.mapAttrs (_: toProvider) active;
  };

  # Default provider / model. While the model list has not been refreshed the
  # keys are omitted entirely, so pi falls back to its own picker instead of
  # pointing at a model that is not in models.json.
  dflt = config.llm.defaultProvider;
  dfltProvider = active.${dflt} or null;
  # elem, not just a non-empty check: defaultModel is pinned by hand in
  # core/llm.nix now, so the gateway retiring that id has to degrade to "no
  # default written" rather than to a default pointing at nothing.
  hasDefault = dfltProvider != null && lib.elem dfltProvider.defaultModel dfltProvider.models;

  settings =
    {
      theme = "dark";

      # Skills are not duplicated for pi. claude.nix already links
      # claude/skills/<name> into ~/.claude/skills, and pi implements the same
      # Agent Skills standard -- pointing at that directory is upstream's own
      # advice for sharing skills between harnesses, and it picks up manually
      # installed ones too. ~ is expanded by pi.
      skills = ["~/.claude/skills"];

      # An anonymous version ping on first run and after every version change.
      # A nix upgrade is a version change, so this would fire on switches.
      enableInstallTelemetry = false;

      # Third-party packages. pi ships four tools -- read, bash, edit, write --
      # and no networking and no MCP; everything past that is a package that
      # registers its own tools.
      #
      #   pi-web-access  web_search / web_fetch, plus PDF and YouTube
      #                  extraction. Works with no API key (bundled Exa,
      #                  keyless DuckDuckGo); keys for Brave / Tavily / Jina /
      #                  Kagi go in ~/.pi/web-search.json, which nix does not
      #                  manage, so adding one later needs no rebuild.
      #   pi-subagents   delegation to subagents, pi's answer to Claude Code's
      #                  Task tool.
      #
      # Declared here rather than installed with `pi install`, which wants to
      # write settings.json back and cannot. pi installs whatever is listed
      # but missing at startup, and compares the pinned version against what
      # is on disk, so bumping the number below *is* the update procedure.
      #
      # Pinned for the reason opencode.nix pins opencode-wakatime: an
      # unpinned spec resolves to latest and moves under you silently. The
      # install lands in ~/.pi/agent/npm/, outside nix, the same unmanaged
      # half Claude Code's plugins live in.
      #
      # Worth stating plainly, because it is upstream's own warning: a pi
      # package runs with full system access. These two are third-party code.
      packages = [
        "npm:pi-web-access@0.20.0"
        "npm:pi-subagents@0.45.2"
      ];
    }
    // lib.optionalAttrs hasDefault {
      defaultProvider = dflt;
      defaultModel = dfltProvider.defaultModel;
    };

  toJson = name: value: (pkgs.formats.json {}).generate name value;
in {
  home.file =
    {
      ".pi/agent/settings.json".source = toJson "pi-settings.json" settings;

      # Home-grown extension: output tok/s in the footer, which pi does not
      # report. ~/.pi/agent/extensions/*.ts is an auto-discovered location, so
      # this needs no matching entry in settings.extensions. pi loads .ts
      # through jiti, so there is nothing to compile.
      ".pi/agent/extensions/tokens-per-second.ts".source = ./pi/tokens-per-second.ts;
    }
    // lib.optionalAttrs (active != {}) {
      ".pi/agent/models.json".source = toJson "pi-models.json" models;
    };

  home.packages = [pkgs.unstable.pi-coding-agent];

  home.sessionVariables.PI_SKIP_VERSION_CHECK = "1";
}
