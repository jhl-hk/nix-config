{inputs, ...}:
#############################################################
#
#  Agent instructions
#
#  The global instruction file is nix-secrets' agents/AGENTS.md (it names the
#  self-hosted git host and the internal project layout, and nix-config is
#  public), linked to ~/.omp/agent/AGENTS.md, omp's user-level context file.
#  Read-only: edit it in nix-secrets, push, then `just update-nix-secrets`.
#
#############################################################
{
  home.file.".omp/agent/AGENTS.md".source = "${inputs.nix-secrets}/agents/AGENTS.md";
}
