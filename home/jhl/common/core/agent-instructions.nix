{inputs, ...}:
#############################################################
#
#  Agent instructions -- one file, every harness
#
#  The global instruction file lives in nix-secrets (it names the self-hosted
#  git host and the internal project layout, and nix-config is public) and is
#  linked here into each harness's own fixed path. One source, so a rule added
#  once binds every agent rather than the one that happened to be asked.
#
#  ~/.claude/CLAUDE.md is deliberately NOT here: claude.nix owns that path and
#  carries the reasoning for why CLAUDE.md is the one file it links read-only.
#
#  -- Why each path ------------------------------------------------------
#
#  Every one of these is a *fixed filename the tool looks for*, not a config
#  key pointing at a path, which is why they are symlinks rather than entries
#  in the respective settings files:
#
#    pi          ~/.pi/agent/AGENTS.md
#                `pi --help` lists --no-context-files "Disable AGENTS.md and
#                CLAUDE.md discovery"; its bundled docs/usage.md documents this
#                as the global file, then parent dirs, then cwd. pi also has
#                SYSTEM.md / APPEND_SYSTEM.md, which replace or append to the
#                system prompt -- a different, blunter mechanism, not used here.
#
#    opencode    ~/.config/opencode/AGENTS.md
#                opencode also has an `instructions` key taking paths and globs,
#                but the fixed file needs no edit to opencode.json, so it wins.
#
#    Antigravity ~/.gemini/config/rules/AGENTS.md
#                Same customization root as its skills.json. agy rejects `~` in
#                its JSON path config (see antigravity.nix), but that does not
#                apply to a symlink on disk.
#
#    codex       ~/.codex/AGENTS.md
#                Read by codex-acp, which zed.nix registers as an ACP server,
#                and by the codex CLI itself -- it belongs to neither module,
#                which is half the reason this file exists.
#
#  harness is absent on purpose: v0.9.0 has no instruction-file mechanism at
#  all. Its whole TOML surface is providers/model/mcp keys, and its only
#  per-repo channel is skills. Delivering these rules there would mean
#  repackaging them as a SKILL.md, which is a different thing -- a skill is
#  loaded when relevant, instructions bind every turn.
#
#  These land on every Mac, including ones without the agent installed, where
#  the file is simply never read. Gating each on its harness would couple core
#  to what is optional, for the sake of an unread 3 kB file.
#
#############################################################
let
  instructions = "${inputs.nix-secrets}/claude/CLAUDE.md";
in {
  home.file = {
    ".pi/agent/AGENTS.md".source = instructions;
    ".config/opencode/AGENTS.md".source = instructions;
    ".gemini/config/rules/AGENTS.md".source = instructions;
    ".codex/AGENTS.md".source = instructions;
  };
}
