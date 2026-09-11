{
  inputs,
  pkgs,
  ...
}:
#############################################################
#
#  Codex CLI -- the WakaTime plugin
#
#  Heartbeats for codex, matching what opencode.nix, claude.nix and
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
#  is /etc/codex/config.toml. Plugin resolution works off the merged result,
#  so declaring the two tables here is equivalent to putting them in the user
#  file -- except that Codex never writes this layer, so there is nothing to
#  merge, nothing to clobber, and the whole thing is a plain
#  `environment.etc` entry that `just check` builds.
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
  environment.etc."codex/config.toml".text = ''
    [marketplaces.wakatime]
    source_type = "local"
    source = "${codexWakatime}"

    [plugins."codex-cli-wakatime@wakatime"]
    enabled = true
  '';
}
