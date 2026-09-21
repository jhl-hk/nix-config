{
  inputs,
  pkgs,
  ...
}:
#############################################################
#
#  Codex CLI -- the system config layer
#
#  Two things, both written into /etc/codex/config.toml: the gateway Codex
#  talks to, and the WakaTime plugin.
#
#  Heartbeats for codex match what opencode.nix, claude.nix and
#  antigravity.nix already declare for the other three harnesses. All four
#  feed one account through one ~/.wakatime.cfg.
#
#  -- Why this is a system module and not a home one ---------------------
#
#  Codex keeps plugin state in ~/.codex/config.toml, and it writes that file
#  itself -- `[projects."<path>"].trust_level` lands there every time a new
#  directory is trusted. A home.file store symlink would make those writes
#  fail with EACCES (the README's read-only-symlink trap), and merging into it
#  from an activation script means parsing and rewriting TOML that Codex owns.
#
#  Codex reads a *stack* of config layers instead, and the lowest-priority one
#  is /etc/codex/config.toml. Resolution works off the merged result, so
#  declaring these tables here is equivalent to putting them in the user file
#  -- except that Codex never writes this layer, so there is nothing to merge,
#  nothing to clobber, and the whole thing is a plain `environment.etc` entry
#  that `just check` builds.
#
#  Being the *lowest* layer is what makes the model keys below fragile in one
#  specific way: a `model` or `model_provider` in ~/.codex/config.toml wins
#  over them, and Codex writes that file itself when a model is picked in the
#  TUI. That is the intended escape hatch -- but it also means a stale key
#  there silently defeats this file. If Codex starts calling a model the
#  gateway does not serve, look in the user file first.
#
#  The cost is the split: this sits in the system tree while
#  home/jhl/common/core/wakatime.nix holds the cfg and
#  hosts/common/optional/darwin/wakatime.nix holds the key. That is the same
#  three-way split WakaTime already has here, for the same reason -- system
#  and home are separate option trees.
#
#  Optional, not core: the `codex` cask lives in
#  hosts/common/optional/darwin/desktop.nix, so jhlsMacBookAir has no codex
#  to configure. Import this file next to that one.
#
#  -- What this does NOT manage ------------------------------------------
#
#  wakatime-cli. The plugin hardcodes ~/.wakatime/wakatime-cli-<os>-<arch>,
#  never consults PATH, and on every SessionStart compares that binary's
#  version against the latest GitHub tag and overwrites it when they differ.
#  Pointing it at the nixpkgs build would not survive the first session, and
#  would not work anyway: the plugin invokes `--sync-ai-heartbeats`, which
#  nixpkgs' 2.14.5 does not have. So the binary is unmanaged and
#  self-updating; only the API key stays declarative, via the
#  api_key_vault_cmd in ~/.wakatime.cfg, which both builds honour.
#
#############################################################
let
  # -- The gateway ---------------------------------------------------------
  #
  # base_url is read from the same file home/jhl/common/core/llm.nix reads, so
  # `just llm-models` repointing the fleet at the fallback gateway reaches
  # Codex too, with no edit here. That file is generated -- never hand-edit it.
  #
  # The other two values are **duplicated** from home/jhl/common/core/llm.nix
  # and there is no way around it: they live in the home option tree
  # (modules/home/llm.nix), which a system module cannot read. Keep them in
  # step with the `llm.providers.JianyueLab` block there -- envVar is named
  # for Zed's UpperSnake conversion, and pinnedDefault is pinned because the
  # gateway stopped listing gpt-5.6-sol in /v1/models while still serving it.
  gateway = {
    inherit (builtins.fromJSON (builtins.readFile ../../../../home/jhl/common/core/llm/active.json)) apiUrl;
    model = "gpt-5.6-sol";
    envVar = "JIANYUE_LAB_API_KEY";
  };

  # Patched, because upstream's scripts/run is a bare `exec node ...` with no
  # fallback. Codex hooks inherit the environment of the terminal that started
  # codex, where node happens to be Homebrew's -- making the plugin silently
  # dependent on a brew that nothing in this repo declares. An absolute store
  # path removes the question.
  codexWakatime =
    pkgs.runCommand "codex-cli-wakatime" {
      src = inputs.wakatime-codex;
    } ''
      cp -r "$src" "$out"
      chmod -R u+w "$out"
      substituteInPlace "$out/plugins/codex-cli-wakatime/scripts/run" \
        --replace-fail 'exec node ' 'exec ${pkgs.nodejs}/bin/node '
    '';
in {
  # source_type = "local" rather than "git": a git marketplace is cloned into
  # ~/.codex/.tmp/marketplaces at runtime and tracks whatever HEAD is, which
  # flake.lock cannot pin. A local source is read straight from the store and
  # never fetched.
  #
  # `source` has to be the repository *root* -- the directory holding
  # .agents/plugins/marketplace.json -- not plugins/codex-cli-wakatime/. The
  # marketplace manifest names the subdirectory itself, and supplies the
  # "wakatime" marketplace name that the plugin key below refers to.
  #
  # WARNING: Codex copies the plugin into
  #    ~/.codex/plugins/cache/wakatime/codex-cli-wakatime/<version>/ and
  #    refreshes that copy only when plugin.json's version changes -- not when
  #    this store path does. An upstream commit that edits code without
  #    bumping 1.0.0 will therefore not take effect on a machine that already
  #    has the cache. After `nix flake update wakatime-codex`, check whether
  #    the version moved, and if it did not:
  #
  #      rm -rf ~/.codex/plugins/cache/wakatime
  # TOML orders itself: bare keys have to precede the first table header, or
  # they are parsed as members of whatever table came last.
  #
  # wire_api = "responses" is the only value Codex still accepts. 0.155.1
  # rejects the whole config file -- not just the provider -- with
  #
  #   /etc/codex/config.toml:8:12: `wire_api = "chat"` is no longer supported.
  #
  # and falls back to ChatGPT auth. So do not copy the `wire_api = "chat"`
  # that llm-web's own Agent Setup page generates: that page is a version
  # behind Codex here. The gateway serves both surfaces, so Responses works.
  #
  # env_key names the variable, never the value: home/jhl/common/core/llm.nix
  # exports it into zsh from /run/secrets, and Codex is terminal-only, so the
  # launchctl half of that file has nothing to do here. A Codex started with
  # no such variable in its environment fails at the first request, not at
  # load -- so an empty `echo $JIANYUE_LAB_API_KEY` is the thing to check.
  environment.etc."codex/config.toml".text = ''
    model = "${gateway.model}"
    model_provider = "jianyuelab"

    [model_providers.jianyuelab]
    name = "JianyueLab AI Gateway"
    base_url = "${gateway.apiUrl}"
    env_key = "${gateway.envVar}"
    wire_api = "responses"

    [marketplaces.wakatime]
    source_type = "local"
    source = "${codexWakatime}"

    [plugins."codex-cli-wakatime@wakatime"]
    enabled = true
  '';
}
