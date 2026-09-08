{
  config,
  lib,
  pkgs,
  ...
}:
#############################################################
#
#  harness -- provider config
#
#  Without this file harness has no config at all, falls back to its built-in
#  defaults, and dies on the first run:
#
#    harness: config: 环境变量 ANTHROPIC_API_KEY 未设置或为空
#
#  That is not a missing key, it is a missing config. harness ships two
#  built-in providers, anthropic and openai, and defaults to anthropic against
#  api.anthropic.com -- an account this fleet does not have. The fix is to
#  declare the gateway it *does* have and point default_provider at it, not to
#  put a gateway key into ANTHROPIC_API_KEY: that key is a jyl- portal
#  credential and api.anthropic.com would simply reject it.
#
#  -- Where the values come from -----------------------------------------
#
#  Nothing here is hand-written. modules/home/llm.nix declares the provider
#  facts once and home/jhl/common/core/llm.nix populates them; zed.nix,
#  opencode.nix and pi.nix all read the same options, and this is the fourth
#  consumer. So `just llm-models` picking the other gateway repoints harness
#  too, with no edit here.
#
#  wire = "openai" is a property of that option tree rather than a choice:
#  modules/home/llm.nix is titled "LLM providers (OpenAI-compatible
#  endpoints)" and its apiUrl option is documented as an OpenAI-compatible base
#  URL. harness's own README shows this gateway with wire = "anthropic" and
#  model = "claude-opus-5" -- do not copy that example. The gateway serves both
#  wire formats, but llm/models.json lists no Claude model at all (it is gpt /
#  grok / qwen / deepseek), so that pairing names a model this gateway will not
#  answer for.
#
#  -- The /v1 that has to come off ---------------------------------------
#
#  apiUrl carries /v1 because that is what Zed and opencode want. harness wants
#  the origin and rejects anything ending in /v1 at load time, because its
#  clients append the protocol path themselves and would otherwise build
#  /v1/v1/... . Same trap Claude Code's ANTHROPIC_BASE_URL has. Hence the
#  removeSuffix below -- it is load-bearing, not tidying.
#
#  -- Why a read-only store symlink is safe here -------------------------
#
#  harness only ever reads this file: config.Load is the single reference to
#  it and there is no writer anywhere in the binary. So it is unlike Claude
#  Code's settings.json or Zed's, which are written back by the app and
#  therefore cannot be a store symlink.
#
#  The path is not a typo and not XDG. harness locates its config with Go's
#  os.UserConfigDir(), which on darwin is $HOME/Library/Application Support and
#  ignores XDG_CONFIG_HOME entirely -- so xdg.configFile would write a file
#  harness never opens. Its README says ~/.config/harness/config.toml, which is
#  the Linux answer. Verified on this machine:
#
#    harness --help
#      -config string  (default "/Users/jhl/Library/Application Support/harness/config.toml")
#
#  Optional rather than core for the reason antigravity.nix records: the brew
#  lives in hosts/common/optional/darwin/dev-extras.nix, so only jhlsMacBookPro
#  and SeandeMac-Studio carry the binary. A config on jhlsMacBookAir would be a
#  configured agent with nothing to run.
#
#############################################################
let
  cfg = config.llm;

  # Same gate the other three consumers use: a provider whose model list has
  # never been refreshed is skipped rather than written out empty.
  active = lib.filterAttrs (_: p: p.models != []) cfg.providers;

  toProvider = _: p: {
    wire = "openai";
    base_url = lib.removeSuffix "/v1" p.apiUrl;
    # The variable name, never the value -- harness reads it with os.Getenv at
    # startup. core/llm.nix already exports it into zsh (and, for GUI
    # processes, via launchctl setenv), so there is no new secret plumbing
    # here: harness picks up the same JIANYUE_LAB_API_KEY opencode uses.
    api_key_env = p.envVar;
    model = p.defaultModel;
  };

  dflt = cfg.defaultProvider;
  dfltProvider = active.${dflt} or null;
  # elem, not a non-empty check, for the reason core/llm.nix spells out: the
  # pinned defaultModel is checked against the refreshed list.
  hasDefault = dfltProvider != null && lib.elem dfltProvider.defaultModel dfltProvider.models;

  settings =
    {
      providers = lib.mapAttrs toProvider active;
    }
    # Writing no default_provider would leave harness on its built-in
    # "anthropic" -- i.e. straight back to the error at the top of this file.
    # Unlike Zed, harness has no UI to pick a provider from, so this is the one
    # key that has to land.
    // lib.optionalAttrs hasDefault {default_provider = dflt;};
in {
  home.file."Library/Application Support/harness/config.toml" =
    lib.mkIf (active != {})
    {
      source = (pkgs.formats.toml {}).generate "harness-config.toml" settings;
    };
}
