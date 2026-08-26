{
  config,
  lib,
  pkgs,
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

  # A native askpass. The obvious choice, Homebrew's ssh-askpass, is an **X11**
  # program: without XQuartz running it cannot open a display and exits
  # non-zero, which OpenSSH reports as "agent refused operation" -- a message
  # that says nothing about the real cause. Verified broken on this machine
  # (no Xquartz process, no /tmp/.X11-unix).
  #
  # This does not bite today only because the SK keys are touch-only. The
  # moment a key needs a PIN (-O verify-required) or a passphrase, ssh-agent
  # calls askpass, gets nothing, and refuses to sign with no useful error.
  #
  # The prompt is passed through argv rather than interpolated into the
  # AppleScript, so a prompt containing a quote cannot break out of the string.
  # A cancelled dialog makes osascript exit non-zero, which is exactly the
  # "user declined" signal OpenSSH expects.
  askpass = pkgs.writeShellScriptBin "ssh-askpass-osascript" ''
    prompt="''${1:-SSH passphrase}"

    # OpenSSH sets this to "confirm" for yes/no prompts (ssh-agent's
    # user-presence and confirmation requests). Those want a button, not a
    # text field -- showing a password box there would be nonsense.
    if [ "''${SSH_ASKPASS_PROMPT:-}" = "confirm" ]; then
      /usr/bin/osascript         -e 'on run argv'         -e '  display dialog (item 1 of argv) buttons {"Cancel", "OK"} default button "OK" with title "SSH" with icon caution'         -e '  if button returned of result is not "OK" then error number -128'         -e 'end run'         -- "$prompt" >/dev/null
      exit $?
    fi

    /usr/bin/osascript       -e 'on run argv'       -e '  display dialog (item 1 of argv) default answer "" with hidden answer with title "SSH" with icon caution'       -e '  return text returned of result'       -e 'end run'       -- "$prompt"
  '';

  # Build a **single line** before interpolating. A multi-line interpolation
  # wrecks the indentation of the whole zsh block: Nix de-indents '' strings by
  # the minimum indentation across all lines, and a line starting with ${...}
  # at column 0 makes that minimum 0, so nothing is stripped and the generated
  # .zshrc carries the source's 4-space indentation throughout.
  keyList = lib.concatMapStringsSep " " (k: ''"$HOME/.ssh/${k}"'') keys;
in {
  home.sessionVariables = {
    SSH_ASKPASS = "${askpass}/bin/ssh-askpass-osascript";

    # DISPLAY is a lie on macOS -- there is no X server -- and it is set on
    # purpose. OpenSSH's readpass.c only reaches for SSH_ASKPASS when
    # SSH_ASKPASS_REQUIRE says so or, failing that, when DISPLAY is non-empty.
    # This is the legacy lever, and it is the one that gives the behaviour we
    # want: ssh-agent, which has no controlling tty, falls through to the GUI
    # dialog, while ssh in a terminal still prompts on the tty.
    #
    # SSH_ASKPASS_REQUIRE would be the modern spelling, but "force"/"prefer"
    # apply to the tty case too, so a plain `ssh` in a terminal would start
    # popping dialogs. Not worth it.
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
