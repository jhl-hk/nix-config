{
  config,
  lib,
  ...
}:
#############################################################
#
#  Zed Configuration
#
#  Zed itself is installed by a Homebrew cask (see
#  hosts/common/darwin/apps.nix), so package = null here and this only manages
#  the config files under ~/.config/zed.
#
#  mutableUserSettings/Keymaps = true (the default):
#  at activation the declarative config below is *merged* into the existing
#  settings.json / keymap.json. Other keys Zed wrote itself are preserved;
#  where names collide, the Nix side wins.
#
#############################################################
let
  # Nix strings have no \u escape, so fromJSON is used to get ESC (0x1b)
  esc = builtins.fromJSON "\"\\u001b\"";

  # ---- openai_compatible generated from modules/home/llm.nix ----
  #
  # The key deliberately never appears here. Zed's docs, verbatim:
  #   "Do not put API keys in settings.json"
  # It looks for a <PROVIDER_ID>_API_KEY environment variable, whose value is
  # injected into the login session by the launchd agent in
  # home/jhl/common/core/llm.nix.
  #
  # Only providers with a refreshed model list are generated -- before
  # `just llm-models` has ever run, available_models would be empty and Zed
  # would just show a provider nothing can be selected from.
  activeLlm = lib.filterAttrs (_: p: p.models != []) config.llm.providers;

  toZedModel = p: name: {
    inherit name;
    max_tokens = p.maxTokens;
    max_output_tokens = p.maxOutputTokens;
    max_completion_tokens = p.maxTokens;
    capabilities = {
      tools = true;
      images = false;
      parallel_tool_calls = false;
      prompt_cache_key = false;
      chat_completions = true;
      interleaved_reasoning = false;
      max_tokens_parameter = false;
    };
  };

  generatedProviders =
    lib.mapAttrs (_: p: {
      api_url = p.apiUrl;
      available_models = map (toZedModel p) p.models;
    })
    activeLlm;

  # The default provider. Before the model list is refreshed it is not in
  # activeLlm, and every default-model-related key below is omitted wholesale
  # -- mutableUserSettings is merge semantics, so writing nothing preserves
  # whatever you picked in the UI, which beats pointing at a nonexistent model.
  dflt = config.llm.defaultProvider;
  dfltProvider = activeLlm.${dflt} or null;
  # elem rather than a non-empty check, because core/llm.nix pins defaultModel
  # by hand: if the gateway retires that id, write no default at all rather
  # than one Zed cannot resolve -- mutableUserSettings keeps the UI's choice.
  hasDefault = dfltProvider != null && lib.elem dfltProvider.defaultModel dfltProvider.models;

  defaultModelRef = {
    provider = dflt;
    model = dfltProvider.defaultModel;
  };
in {
  programs.zed-editor = {
    enable = true;
    package = null; # use the Homebrew cask's Zed

    # Extensions auto-installed at startup (written as auto_install_extensions
    # in settings.json). Names are extension repo names, see
    # https://github.com/zed-industries/extensions
    extensions = [
      # Themes / icons
      "catppuccin"
      "catppuccin-icons"
      "macos-classic"

      # Languages
      "astro"
      "csv"
      "dockerfile"
      "html"
      "just"
      "make"
      "nix"
      "prisma"
      "svelte"
      "toml"
      "vue"
      "bird2" # BIRD routing daemon config

      # Tools
      "git-firefly"
      "wakatime"
      "discord-presence"
    ];

    userSettings = {
      # ---- Appearance ----
      theme = {
        mode = "system";
        light = "One Light";
        dark = "Catppuccin Mocha";
      };
      icon_theme = "Catppuccin Mocha";
      ui_font_size = 16;
      buffer_font_size = 13;
      buffer_font_family = "Maple Mono";
      buffer_font_features = {
        calt = true; # ligatures
      };

      # ---- Panel docking ----
      project_panel.dock = "right";
      outline_panel.dock = "right";
      collaboration_panel.dock = "right";
      git_panel.dock = "right";

      # ---- Editor ----
      tab_size = 2;
      show_completions_on_input = false;

      languages = {
        Prisma = {
          formatter.external = {
            command = "bunx";
            arguments = ["prettier" "--stdin-filepath" "{buffer_path}"];
          };
          format_on_save = "on";
        };
      };

      # ---- AI ----
      disable_ai = false;
      show_edit_predictions = true;

      # Entirely generated from llm.providers; no providers are hand-written
      # here any more.
      #
      # WARNING: deleting a provider from nix does **not** delete it from the
      #    settings.json on disk. mutableUserSettings is a one-way merge: keys
      #    nix declares overwrite same-named ones, and keys nix no longer
      #    declares are left untouched. The old Local / Redtea / Taizhou Local
      #    entries have to be removed from ~/.config/zed/settings.json by hand,
      #    once.
      language_models.openai_compatible = generatedProviders;

      agent =
        {
          dock = "left";
          favorite_models = [];
          model_parameters = [];
          commit_message_instructions = "Use the Conventional Commits format: <type>(<scope>): <description>.";
        }
        // lib.optionalAttrs hasDefault {
          default_model = defaultModelRef // {enable_thinking = false;};
          commit_message_model = defaultModelRef;
        };

      agent_servers = {
        gemini.type = "registry";
        codex-acp.type = "registry";
        claude-acp = {
          type = "registry";
          default_config_options = {
            mode = "auto";
            effort = "default";
            fast = false;
          };
        };
      };

      edit_predictions =
        {
          provider = "copilot";
        }
        // lib.optionalAttrs hasDefault {
          open_ai_compatible_api = {
            model = dfltProvider.defaultModel;
            api_url = dfltProvider.apiUrl;
          };
        };
    };

    userKeymaps = [
      {
        context = "Terminal";
        bindings = {
          shift-enter = ["terminal::SendText" "${esc}\r"];
        };
      }
    ];
  };
}
