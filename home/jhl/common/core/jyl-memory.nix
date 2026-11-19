{pkgs, ...}:
#############################################################
#
#  jyl-memory -- session memory for omp
#
#  The plugin is plugins/jyl-memory in JianyueLab/claude-plugin. At session
#  start it tells the agent to search the memory service; at session end a
#  background worker distils the new text through `omp -p` into the personal
#  memory project. The hook is ~/.omp/agent/hooks/post/jyl-memory.ts, linked
#  by ../optional/ai/omp.nix from a pinned input.
#
#  This file pins the runtime the hook runs on. The plugin's launcher takes
#  JYL_MEMORY_RUNTIME first, then bun, then node from PATH. Exported from
#  .zshrc rather than home.sessionVariables: hm-session-vars.sh skips itself
#  in shells whose ancestor sourced an older generation.
#
#  Prerequisite: the memory MCP server (modules/home/mcp-servers.nix) signed
#  in to omp.
#
#  Check after a session ends:
#
#    tail ~/.local/state/jyl-memory/plugin.log
#
#  "distilled N messages" means memories were written; "failed no-done"
#  usually means the memory MCP is not signed in.
#
#############################################################
{
  programs.zsh.initContent = ''
    export JYL_MEMORY_RUNTIME="${pkgs.nodejs}/bin/node"
  '';
}
