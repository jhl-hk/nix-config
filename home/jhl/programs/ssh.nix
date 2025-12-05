{ config, pkgs, ... }:

#############################################################
#
#  SSH Configuration with YubiKey Support
#
#############################################################

{
  programs.ssh = {
    enable = true;

    # SSH agent configuration for YubiKey
    extraConfig = ''
      # YubiKey hardware key support
      IdentityAgent SSH_AUTH_SOCK
    '';
  };

  # SSH agent service configuration
  services.ssh-agent = {
    enable = true;
  };

  # Shell initialization for SSH agent and YubiKey
  programs.zsh.initExtra = ''
    # Homebrew prefix
    BREW_PREFIX="$(brew --prefix)"

    # Start ssh-agent if not running
    if [ -z "$SSH_AUTH_SOCK" ] || ! pgrep -u "$USER" ssh-agent > /dev/null; then
      eval "$($BREW_PREFIX/bin/ssh-agent -s)" > /dev/null
    fi

    # Set SSH_ASKPASS for GUI password prompts
    export SSH_ASKPASS="$BREW_PREFIX/bin/ssh-askpass"
    export DISPLAY=":0"

    # Auto-load YubiKey SSH key
    SSH_KEY="$HOME/.ssh/id_ed25519_sk_rk"
    if [ -f "$SSH_KEY" ]; then
      "$BREW_PREFIX/bin/ssh-add" "$SSH_KEY" 2>/dev/null
    fi
  '';

  # Session variables for SSH
  home.sessionVariables = {
    # Ensure SSH_AUTH_SOCK persists across sessions
    SSH_AUTH_SOCK = "\${SSH_AUTH_SOCK:-$HOME/.ssh/agent.sock}";
  };
}
