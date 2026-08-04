{...}:
#############################################################
#
#  Zed Configuration
#
#  Zed 本体由 Homebrew cask 安装（见 hosts/common/darwin/apps.nix），
#  所以这里 package = null，只托管 ~/.config/zed 下的配置文件。
#
#  mutableUserSettings/Keymaps = true（默认）：
#  激活时把下面的声明式配置 *合并* 进现有的 settings.json / keymap.json，
#  Zed 自己写进去的其它键会被保留，同名键以 Nix 这边为准。
#
#############################################################
let
  # Nix 字符串没有 \u 转义，用 fromJSON 拿到 ESC (0x1b)
  esc = builtins.fromJSON "\"\\u001b\"";
in {
  programs.zed-editor = {
    enable = true;
    package = null; # 用 Homebrew cask 的 Zed

    # 启动时自动安装的扩展（写成 settings.json 的 auto_install_extensions）
    # 名字 = extension 仓库名，见 https://github.com/zed-industries/extensions
    extensions = [
      # 主题 / 图标
      "catppuccin"
      "catppuccin-icons"
      "macos-classic"

      # 语言
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
      "bird2" # BIRD 路由守护进程配置

      # 工具
      "git-firefly"
      "wakatime"
      "discord-presence"
    ];

    userSettings = {
      # ---- 外观 ----
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
        calt = true; # 连字
      };

      # ---- 面板停靠 ----
      project_panel.dock = "right";
      outline_panel.dock = "right";
      collaboration_panel.dock = "right";
      git_panel.dock = "right";

      # ---- 编辑器 ----
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

      language_models.openai_compatible = {
        "Local" = {
          api_url = "http://192.168.17.250:8080/v1";
          available_models = [
            {
              name = "deepseek-v4-flash";
              max_tokens = 200000;
              max_output_tokens = 32000;
              max_completion_tokens = 200000;
              capabilities = {
                tools = true;
                images = false;
                parallel_tool_calls = false;
                prompt_cache_key = false;
                chat_completions = true;
                interleaved_reasoning = false;
                max_tokens_parameter = false;
              };
            }
          ];
        };
        "Redtea" = {
          api_url = "https://llm.redcoke.dev/v1";
          available_models = [
            {
              name = "gpt-5.6";
              max_tokens = 200000;
              max_output_tokens = 32000;
              max_completion_tokens = 200000;
              capabilities = {
                tools = true;
                images = false;
                parallel_tool_calls = false;
                prompt_cache_key = false;
                chat_completions = true;
                interleaved_reasoning = false;
                max_tokens_parameter = false;
              };
            }
          ];
        };
      };

      agent = {
        default_model = {
          provider = "Redtea";
          model = "gpt-5.6";
          enable_thinking = false;
        };
        dock = "left";
        favorite_models = [];
        model_parameters = [];
        commit_message_model = {
          provider = "openai-subscribed";
          model = "gpt-5.5";
        };
        commit_message_instructions = "Use the Conventional Commits format: <type>(<scope>): <description>.";
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

      edit_predictions = {
        provider = "copilot";
        open_ai_compatible_api = {
          model = "gpt-5.5";
          api_url = "https://llm.redcoke.dev/v1";
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
