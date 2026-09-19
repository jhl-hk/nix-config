{...}:
#############################################################
#
#  Grok Build -- the same setup as Claude Code, by inheritance
#
#  The binary is the "grok-build" cask in
#  hosts/common/optional/darwin/desktop.nix, next to claude-code.
#
#  Nothing is linked into ~/.grok, on purpose. Grok Build ships a Claude
#  compatibility layer ([compat.claude] in ~/.grok/config.toml) with every
#  switch on by default, and `grok inspect` on 1.0.34 shows it picking up,
#  straight from what claude.nix already manages:
#
#    ~/.claude/CLAUDE.md          as the global instruction file
#    ~/.claude/settings.json      permissions and hooks
#    ~/.claude/skills/*           every linked skill
#    ~/.claude/plugins            superpowers, claude-code-wakatime, jyl-usage,
#                                 hooks included
#
#  So one source keeps binding both harnesses. That is also why this file is
#  not in agent-instructions.nix: a ~/.grok/AGENTS.md would be read *in
#  addition to* CLAUDE.md, loading the same rules twice.
#
#  ~/.grok/config.toml is not managed either: grok writes it back itself
#  (/compact-mode, `grok mcp enable`, `grok plugin marketplace add`), the same
#  read-only-symlink trap claude.nix records for settings.json.
#
#############################################################
{
  # Homebrew owns the binary; a self-update would replace the cask's copy in
  # place and fight the next brew upgrade -- same reasoning as opencode's
  # autoupdate = false. An environment variable rather than
  # [cli] auto_update, because config.toml stays unmanaged (see above).
  home.sessionVariables.GROK_DISABLE_AUTOUPDATER = "1";
}
