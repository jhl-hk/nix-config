# SSH Agent configuration for Darwin - optimized for performance
# Single ssh-agent instance shared across all terminals with lazy key loading
{
  pkgs,
  lib,
  ...
}:

#############################################################
#
#  SSH Configuration with YubiKey Support
#  Migrated to Nix-managed SSH with performance optimizations
#
#############################################################

{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "*" = {
        identityFile = "~/.ssh/id_ed25519_sk_rk";
        forwardAgent = true;
        serverAliveInterval = 60;
        serverAliveCountMax = 3;

        extraOptions = {
          AddKeysToAgent = "yes";
          Compression = "yes";
          ControlMaster = "auto";
          ControlPath = "~/.ssh/master-%r@%n:%p";
          ControlPersist = "10m";
        };
      };
    };
  };

  # Environment variables for SSH
  home.sessionVariables = {
    SSH_ASKPASS = "/opt/homebrew/bin/ssh-askpass";
    DISPLAY = ":0";
  };

  # SSH agent configuration with single-instance guarantee
  programs.zsh.initContent = lib.mkAfter ''
    # ===== SSH Agent Management - Performance Optimized =====

    # Use Homebrew-provided SSH tools (OpenSSH with YubiKey support)
    NIX_SSH_ADD="/opt/homebrew/bin/ssh-add"
    NIX_SSH_AGENT="/opt/homebrew/bin/ssh-agent"

    # Use fixed socket path for stability (survives restarts, accessible by root)
    SSH_AUTH_SOCK="$HOME/.ssh/ssh-agent.sock"
    export SSH_AUTH_SOCK

    # Start or connect to existing agent (fast path)
    _ssh_agent_start() {
      # Check if socket exists and agent is responsive
      if [ -S "$SSH_AUTH_SOCK" ]; then
        # Quick check: can we list keys? (agent is alive)
        if $NIX_SSH_ADD -l >/dev/null 2>&1; then
          return 0
        fi
      fi

      # Clean up stale socket
      [ -e "$SSH_AUTH_SOCK" ] && rm -f "$SSH_AUTH_SOCK"

      # Start new agent with fixed socket path
      $NIX_SSH_AGENT -a "$SSH_AUTH_SOCK" -s >/dev/null
      chmod 600 "$SSH_AUTH_SOCK"
    }

    # Load SSH keys lazily (only when first needed)
    ssh() {
      # Fast path: if keys already loaded, just run ssh
      if $NIX_SSH_ADD -l >/dev/null 2>&1; then
        command ssh "$@"
        return
      fi

      # Keys not loaded yet, load them now
      local keys=(
        "$HOME/.ssh/id_ed25519_sk_rk"
      )

      for key in "''${keys[@]}"; do
        [ -f "$key" ] && $NIX_SSH_ADD "$key" 2>/dev/null
      done

      command ssh "$@"
    }

    # Initialize agent connection (non-blocking)
    _ssh_agent_start

    # Aliases (using Nix ssh-add)
    alias ssh-list="$NIX_SSH_ADD -l"
    alias ssh-clear="$NIX_SSH_ADD -D"
  '';
}
