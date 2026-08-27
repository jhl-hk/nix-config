{
  config,
  lib,
  ...
}:
#############################################################
#
#  SSH Agent (macOS)
#
#  All terminals share a single ssh-agent instance, with keys loaded on demand.
#  Uses Homebrew's OpenSSH (which has YubiKey sk support), not the system one.
#
#  Split out of ssh.nix: this whole section is /opt/homebrew paths and only
#  holds on macOS.
#
#############################################################
let
  keys = [config.sshKeys.primary] ++ config.sshKeys.extra;

  # Build a **single line** before interpolating. A multi-line interpolation
  # wrecks the indentation of the whole zsh block: Nix de-indents '' strings by
  # the minimum indentation across all lines, and a line starting with ${...}
  # at column 0 makes that minimum 0, so nothing is stripped and the generated
  # .zshrc carries the source's 4-space indentation throughout.
  keyList = lib.concatMapStringsSep " " (k: ''"$HOME/.ssh/${k}"'') keys;
in {
  home.sessionVariables = {
    SSH_ASKPASS = "/opt/homebrew/bin/ssh-askpass";
    DISPLAY = ":0";
  };

  programs.zsh.initContent = lib.mkAfter ''
    export PATH="$HOME/.local/bin:$PATH"

    # ===== SSH Agent Management - Performance Optimized =====

    NIX_SSH_ADD="/opt/homebrew/bin/ssh-add"
    NIX_SSH_AGENT="/opt/homebrew/bin/ssh-agent"

    # Fixed socket path: survives restarts and is reachable by root too
    SSH_AUTH_SOCK="$HOME/.ssh/ssh-agent.sock"
    export SSH_AUTH_SOCK

    _ssh_agent_start() {
      if [ -S "$SSH_AUTH_SOCK" ]; then
        # `ssh-add -l` exits 2 only when it cannot reach the agent; a live
        # agent with no keys loaded exits 1. Testing only for success would
        # treat a live-but-empty agent as dead, killing the socket and starting
        # a new agent for every new shell. Hence the != 2 test.
        $NIX_SSH_ADD -l >/dev/null 2>&1
        if [ $? -ne 2 ]; then
          return 0
        fi
      fi

      [ -e "$SSH_AUTH_SOCK" ] && rm -f "$SSH_AUTH_SOCK"

      $NIX_SSH_AGENT -a "$SSH_AUTH_SOCK" -s >/dev/null
      chmod 600 "$SSH_AUTH_SOCK"
    }

    # Lazy key loading: only add them the first time they are actually needed
    ssh() {
      if $NIX_SSH_ADD -l >/dev/null 2>&1; then
        command ssh "$@"
        return
      fi

      local keys=( ${keyList} )

      for key in "''${keys[@]}"; do
        [ -f "$key" ] && $NIX_SSH_ADD "$key" 2>/dev/null
      done

      command ssh "$@"
    }

    _ssh_agent_start

    alias ssh-list="$NIX_SSH_ADD -l"
    alias ssh-clear="$NIX_SSH_ADD -D"
  '';
}
