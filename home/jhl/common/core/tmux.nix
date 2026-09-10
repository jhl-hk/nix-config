{...}:
#############################################################
#
#  tmux Configuration
#
#  tmux itself is installed by Homebrew (see hosts/common/darwin/apps.nix), so
#  package = null and this only manages ~/.config/tmux/tmux.conf.
#
#  Scroll behaviour: scrolling up enters copy-mode directly and moves **one
#  line** at a time, rather than tmux's default of 5.
#
#############################################################
{
  programs.tmux = {
    enable = true;
    package = null; # use Homebrew's tmux

    # Without `set -g mouse on`, wheel events never reach tmux at all
    mouse = true;

    extraConfig = ''
      # ---- extended keys --------------------------------------------------
      # Lets tmux forward modified keys (Shift+Enter, Ctrl+Enter, ...) as CSI u
      # sequences instead of collapsing them onto the plain key. pi warns at
      # startup when this is off, because its multi-line input is Shift+Enter.
      set -g extended-keys on

      # ---- wheel = one line -----------------------------------------------
      # Scrolling up in normal mode:
      #   - if the pane runs a fullscreen program (vim / less and friends, which
      #     use the alternate screen) or is already in copy-mode
      #     -> forward the event as-is (send -M)
      #   - otherwise enter copy-mode and scroll up one line
      # copy-mode -e: leaves copy-mode automatically when scrolled back to the
      # bottom
      bind -n WheelUpPane if -F "#{||:#{pane_in_mode},#{mouse_any_flag}}" {
        send -M
      } {
        copy-mode -e
        send -X scroll-up
      }

      # Inside copy-mode: one wheel notch = one line. scroll-up/down move a
      # single line unless given -N, so this overrides tmux's default of 5.
      bind -T copy-mode    WheelUpPane   send -X scroll-up
      bind -T copy-mode    WheelDownPane send -X scroll-down
      bind -T copy-mode-vi WheelUpPane   send -X scroll-up
      bind -T copy-mode-vi WheelDownPane send -X scroll-down
    '';
  };
}
