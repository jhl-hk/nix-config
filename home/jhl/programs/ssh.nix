{ config, pkgs, ... }:

#############################################################
#
#  SSH Configuration with YubiKey Support
#
#############################################################

{
  # Override SSH_AUTH_SOCK early in shell initialization
  # This prevents macOS from using the launchd system agent
  programs.zsh.envExtra = ''
    # Unset system SSH_AUTH_SOCK inherited from launchd
    if [[ "$SSH_AUTH_SOCK" == *"launchd"* ]]; then
      unset SSH_AUTH_SOCK
    fi

    # Set FIDO2 security key provider for YubiKey support
    export SSH_SK_PROVIDER=/opt/homebrew/opt/libfido2/lib/libfido2.dylib
  '';

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    matchBlocks."*" = {
      identityFile = "~/.ssh/id_ed25519_sk_rk";
      forwardAgent = true;
      serverAliveInterval = 60;
      serverAliveCountMax = 3;

      # Default values from Home Manager
      extraOptions = {
        AddKeysToAgent = "yes";
        Compression = "yes";
        ControlMaster = "auto";
        ControlPath = "~/.ssh/master-%r@%n:%p";
        ControlPersist = "10m";
      };
    };
  };

  # Shell initialization for SSH agent and YubiKey
  programs.zsh.initContent = ''
    # Homebrew prefix
    BREW_PREFIX="$(brew --prefix)"

    # Kill any system SSH agent if running (macOS keeps restarting it)
    if pgrep -u "$USER" -f "/usr/bin/ssh-agent" > /dev/null; then
      pkill -9 -u "$USER" -f "/usr/bin/ssh-agent" 2>/dev/null
    fi

    # Start Homebrew ssh-agent if not already running
    if ! pgrep -u "$USER" -f "$BREW_PREFIX/bin/ssh-agent" > /dev/null; then
      eval "$($BREW_PREFIX/bin/ssh-agent -s)" > /dev/null
    fi

    # Always use Homebrew agent socket (never the system one)
    AGENT_SOCK=$(find ~/.ssh/agent -name "*.agent.*" 2>/dev/null | head -n 1)
    if [ -z "$AGENT_SOCK" ]; then
      # Fallback: search in /tmp but exclude launchd sockets
      AGENT_SOCK=$(find /tmp -path "*/ssh-*/agent.*" -user "$USER" ! -path "*/com.apple.launchd.*" 2>/dev/null | head -n 1)
    fi

    if [ -n "$AGENT_SOCK" ] && [ -S "$AGENT_SOCK" ]; then
      export SSH_AUTH_SOCK="$AGENT_SOCK"
      export SSH_AGENT_PID=$(pgrep -u "$USER" -f "$BREW_PREFIX/bin/ssh-agent")
    fi

    # Set SSH_ASKPASS for GUI password prompts (required for YubiKey)
    export SSH_ASKPASS="$BREW_PREFIX/bin/ssh-askpass"
    export DISPLAY=":0"

    # Auto-load YubiKey SSH key
    SSH_KEY="$HOME/.ssh/id_ed25519_sk_rk"
    if [ -f "$SSH_KEY" ]; then
      # Check if key is already loaded
      if ! "$BREW_PREFIX/bin/ssh-add" -l 2>/dev/null | grep -q "ED25519-SK"; then
        "$BREW_PREFIX/bin/ssh-add" "$SSH_KEY" 2>/dev/null
      fi
    fi
  '';
}
