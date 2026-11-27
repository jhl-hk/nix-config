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
#  omp -- oh-my-pi (https://github.com/can1357/oh-my-pi), the coding agent
#
#  The binary is the can1357/tap/omp brew in
#  hosts/common/optional/darwin/dev-extras.nix on the Macs, and the distro
#  package on jhlsTokyoDesktop. Global instructions are linked by
#  ../../core/agent-instructions.nix, skills by ../../core/skills.nix.
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
#  ~/.omp/agent/models.yml is a consumer of llm.providers, next to Zed.
#  apiKey is an environment variable *name*: omp looks it up and, if unset,
#  sends the literal string. The variable is exported by
#  home/jhl/common/core/llm.nix.
#
#  -- MCP servers ---------------------------------------------------------
#
#  omp.mcpServers (the shared remote list from modules/home/mcp-servers.nix
#  plus anything another module adds, e.g. blender-mcp.nix) is merged into
#  ~/.omp/agent/mcp.json by name. omp writes that file too (`/mcp add`), so
#  it is not linked from the store; entries added there by hand survive.
#
#############################################################
let
  active = lib.filterAttrs (_: p: p.models != []) config.llm.providers;

  # Every gateway model reasons, and the gateway accepts exactly these
  # efforts.
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
    # The gateway rejects role "developer".
    compat.supportsDeveloperRole = false;
    models = map (toModel p) p.models;
  };

  overlay = {
    # brew / pacman own updates (`just update`, or `omp update`).
    startup.checkUpdate = false;
    update.auto = false;

    # Choices made in the setup wizard, pinned so every machine matches.
    modelRoles.default = "anthropic/claude-opus-5-5";
    # Subagent dispatches may name their model per call (task and eval).
    # Grants come from configured modelRoles, the agent's own frontmatter
    # model and the parent's live model; no extra roles are set yet.
    task.perCallModel = "on";
    defaultThinkingLevel = "auto";
    statusLine = {
      preset = "custom";
      separator = "pipe";
      # Only the box composer draws a context line.
      contextLine = "off";
      leftSegments = ["vim" "model" "mode" "git" "pr" "subagents"];
      # Most important first: segments that overflow are dropped from the end.
      rightSegments = ["context_pct" "cost" "token_rate" "token_in" "token_out" "cache_hit" "time_spent" "session_name"];
      segmentOptions.git = {
        showBranch = true;
        showStaged = true;
        showUnstaged = true;
        showUntracked = false;
      };
      sessionAccent = true;
      showHookStatus = true;
    };

    # Nerd Font icons: Ghostty bundles them; Maple Mono (Zed's terminal) does
    # not, so they show as fallback glyphs there.
    symbolPreset = "nerd";
    composer.shape = "rail";
    # omp picks theme.light on a light terminal background.
    theme = {
      dark = "dark-poimandres";
      light = "light-poimandres";
    };
  };

  yaml = pkgs.formats.yaml {};
  overlayFile = ".omp/agent/nix.yml";
  mcpJsonPath = "${config.home.homeDirectory}/.omp/agent/mcp.json";

  mergeMcp = pkgs.writeText "merge-omp-mcp.py" ''
    import json, os, sys, tempfile

    path, servers = sys.argv[1], json.loads(sys.argv[2])
    try:
        with open(path, encoding="utf-8") as f:
            data = json.load(f)
    except FileNotFoundError:
        data = {}
    data["mcpServers"] = {**data.get("mcpServers", {}), **servers}

    os.makedirs(os.path.dirname(path), exist_ok=True)
    fd, tmp = tempfile.mkstemp(dir=os.path.dirname(path), prefix=".mcp.json.")
    with os.fdopen(fd, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2)
    os.replace(tmp, path)
  '';
in {
  options.omp.mcpServers = lib.mkOption {
    type = lib.types.attrsOf (lib.types.attrsOf lib.types.anything);
    default = {};
    description = "MCP servers merged into ~/.omp/agent/mcp.json, keyed by name.";
  };

  config = {
    omp.mcpServers =
      lib.mapAttrs (_: s: {
        type = "http";
        inherit (s) url;
      })
      config.mcpServers;

    home.activation.ompMcpServers = lib.hm.dag.entryAfter ["writeBoundary"] ''
      if [[ -v DRY_RUN ]]; then
        echo "omp.nix: would merge MCP servers into ${mcpJsonPath}"
      elif ! ${pkgs.python3}/bin/python3 -I ${mergeMcp} \
        ${lib.escapeShellArg mcpJsonPath} \
        ${lib.escapeShellArg (builtins.toJSON config.omp.mcpServers)}; then
        echo "omp.nix: MCP merge failed, left ${mcpJsonPath} untouched" >&2
      fi
    '';

    home.file =
      {
        ${overlayFile}.source = yaml.generate "omp-nix.yml" overlay;

        # jyl-memory's omp half (see ../../core/jyl-memory.nix). omp loads
        # hooks/post/*.ts and ignores the plugin's hooks/hooks.json. omp
        # resolves the symlink, so the hook finds scripts/run next to itself in
        # the store.
        ".omp/agent/hooks/post/jyl-memory.ts".source = "${inputs.jianyuelab-plugins}/plugins/jyl-memory/hooks/post/jyl-memory.ts";

        # WakaTime heartbeats (wakatime-omp, pinned input). omp auto-loads
        # extensions/*.ts. The extension takes the first wakatime-cli on PATH,
        # which ../../core/wakatime.nix installs; that build must be new enough
        # to carry wakatime-cli's OMP transcript parser (pkg/ai/omp.go, absent
        # from 2.14.5). The key comes from ../../core/wakatime.nix.
        ".omp/agent/extensions/wakatime.ts".source = "${inputs.wakatime-omp}/src/extension.ts";

        ".omp/agent/models.yml".source = yaml.generate "omp-models.yml" {
          providers = lib.mapAttrs (_: toProvider) active;
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

    home.sessionVariables.PI_CONFIG_FILES = "${config.home.homeDirectory}/${overlayFile}";
  };
}
