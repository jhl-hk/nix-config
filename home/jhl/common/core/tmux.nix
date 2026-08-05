{...}:
#############################################################
#
#  tmux Configuration
#
#  tmux itself is installed by Homebrew (see hosts/common/darwin/apps.nix), so
#  package = null and this only manages ~/.config/tmux/tmux.conf.
#
#  Scroll behaviour: scrolling up enters copy-mode directly and moves a **full
#  page** at a time, rather than tmux's default of 5 lines.
#
#############################################################
{
  programs.tmux = {
    enable = true;
    package = null; # use Homebrew's tmux

    # Without `set -g mouse on`, wheel events never reach tmux at all
    mouse = true;

    extraConfig = ''
      # ---- wheel = page ---------------------------------------------------
      # Scrolling up in normal mode:
      #   - if the pane runs a fullscreen program (vim / less and friends, which
      #     use the alternate screen) or is already in copy-mode
      #     -> forward the event as-is (send -M)
      #   - otherwise enter copy-mode and page up immediately
      # copy-mode -e: leaves copy-mode automatically when scrolled back to the
      # bottom
      bind -n WheelUpPane if -F "#{||:#{pane_in_mode},#{mouse_any_flag}}" {
        send -M
      } {
        copy-mode -e
        send -X page-up
      }

      # Inside copy-mode: one wheel notch = one full page (overrides the
      # default scroll-up/down of 5 lines)
      bind -T copy-mode    WheelUpPane   send -X page-up
      bind -T copy-mode    WheelDownPane send -X page-down
      bind -T copy-mode-vi WheelUpPane   send -X page-up
      bind -T copy-mode-vi WheelDownPane send -X page-down
    '';
  };
}
