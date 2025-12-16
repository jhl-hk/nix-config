{ config, pkgs, ... }:

#############################################################
#
#  SSH Configuration with YubiKey Support
#  Based on: https://www.homelabproject.cc/posts/macos/macos-yubikey-ssh/
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

      # Tokyo Internet Exchange Point
      "tyix" = {
        hostname = "10.100.11.254";
        user = "root";
      };

      "vultr-ty" = {
        hostname = "202.182.105.203";
        user = "root";
      };
    };
  };

  # Shell initialization for SSH agent
  # Based on: https://www.homelabproject.cc/posts/macos/macos-yubikey-ssh/
  programs.zsh.initContent = ''
    # Homebrew installation path
    BREW_PREFIX="$(brew --prefix)"

    # Kill any system SSH agent (macOS launchd agent)
    if [[ "$SSH_AUTH_SOCK" == *"launchd"* ]]; then
      unset SSH_AUTH_SOCK
    fi

    # Check if socket exists and is valid, if not unset it
    if [ -n "$SSH_AUTH_SOCK" ] && [ ! -S "$SSH_AUTH_SOCK" ]; then
      unset SSH_AUTH_SOCK
    fi

    # Start Homebrew ssh-agent if not running
    if [ -z "$SSH_AUTH_SOCK" ] || ! pgrep -u "$USER" ssh-agent > /dev/null; then
        eval "$($BREW_PREFIX/bin/ssh-agent -s)" > /dev/null
    fi

    # Set SSH_ASKPASS for GUI password prompts (required for YubiKey)
    export SSH_ASKPASS="$BREW_PREFIX/bin/ssh-askpass"
    export DISPLAY=":0"
  '';
}
