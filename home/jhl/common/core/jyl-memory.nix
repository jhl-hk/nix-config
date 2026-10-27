{pkgs, ...}:
#############################################################
#
#  jyl-memory -- session memory for Claude Code, Codex and omp
#
#  The plugin is plugins/jyl-memory in JianyueLab/claude-plugin. At session
#  start it tells the agent to search the memory service; at session end a
#  background worker distils the new text through the harness's own CLI
#  (`claude -p`, `codex exec`, `omp -p`) into the personal memory project.
#
#  Wired once per harness:
#
#    Claude Code  enabledPlugins in ./claude.nix (marketplace
#                 jianyuelab-claude, cloned by Claude Code at runtime)
#    Codex        /etc/codex/config.toml in
#                 hosts/common/optional/darwin/codex.nix (pinned input)
#    omp          ~/.omp/agent/hooks/post/jyl-memory.ts in
#                 ../optional/ai/omp.nix (pinned input)
#
#  This file pins the runtime the hooks run on. The plugin's launcher takes
#  JYL_MEMORY_RUNTIME first, then bun, then node from PATH. Exported from
#  .zshrc rather than home.sessionVariables for the reason ./jyl-usage.nix
#  records: hm-session-vars.sh skips itself in shells whose ancestor sourced
#  an older generation.
#
#  Prerequisite: the memory MCP server (modules/home/mcp-servers.nix) signed
#  in for each harness -- /mcp in Claude Code, `codex mcp login memory`.
#  Codex also asks to trust the plugin's two hooks once, in /hooks.
#
#  Check after a session ends:
#
#    tail ~/.local/state/jyl-memory/plugin.log
#
#  "distilled N messages" means memories were written; "failed no-done"
#  usually means the memory MCP is not signed in for that harness.
#
#############################################################
{
  programs.zsh.initContent = ''
    export JYL_MEMORY_RUNTIME="${pkgs.nodejs}/bin/node"
  '';
}
