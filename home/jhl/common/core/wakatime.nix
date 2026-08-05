{pkgs, ...}:
#############################################################
#
#  wakatime-cli configuration
#
#  ~/.wakatime.cfg is the one file every WakaTime consumer on these machines
#  reads, because they all shell out to the same wakatime-cli:
#
#    opencode      opencode-wakatime plugin, declared in opencode.nix
#    Claude Code   claude-code-wakatime, installed through Claude's plugin
#                  marketplace -- user state, not managed here
#    Zed           the wakatime extension in optional/editors/zed.nix
#    wakatime cask the menu-bar app from apps.nix
#
#  wakatime-cli itself comes from nixpkgs via opencode.nix; both plugins run
#  `which wakatime-cli` and skip their own download when it resolves.
#
#  -- Why this file can be nix-managed at all ----------------------------
#
#  Only because it holds no secret. api_key_vault_cmd makes wakatime-cli run a
#  command and take stdout as the key, so the key stays in sops and this file
#  just points at the decrypted path.
#
#  WARNING: /run/secrets/wakatime/api_key is kept consistent **by hand** with
#     the sops.secrets key name in hosts/common/optional/darwin/wakatime.nix.
#     System modules and home modules are separate option trees and cannot
#     reference each other -- the same split llm.apiKeyFile lives with.
#
#  -- What managing it costs ---------------------------------------------
#
#  home.file is a read-only symlink into the store, so every write path into
#  this file is now closed: `wakatime-cli --config-write`, and Zed's extension
#  when it wants to store an API key you typed into the UI. Both would fail
#  with EACCES rather than silently -- add the setting here and rebuild
#  instead. This is the trade-off the README's "read-only store symlink" trap
#  describes, taken deliberately.
#
#  Runtime state is unaffected: wakatime-cli keeps that in ~/.wakatime/
#  (wakatime-internal.cfg, offline_heartbeats.bdb, wakatime.log), all still
#  writable and none of it managed here.
#
#  Available settings: https://github.com/wakatime/wakatime-cli/blob/develop/USAGE.md
#
#############################################################
{
  home.file.".wakatime.cfg".source = (pkgs.formats.ini {}).generate "wakatime.cfg" {
    settings = {
      # sh -c is what runs this, and stdout is TrimSpace'd (loadAPIKey in
      # wakatime-cli's pkg/params/params.go), so an absolute path plus the
      # trailing newline of a decrypted file are both fine.
      #
      # Deliberately no api_key next to it: loadAPIKey returns that first and
      # only falls through to the vault command when it is empty.
      api_key_vault_cmd = "/bin/cat /run/secrets/wakatime/api_key";
    };
  };
}
