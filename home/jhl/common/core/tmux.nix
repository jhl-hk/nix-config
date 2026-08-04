{...}:
#############################################################
#
#  tmux Configuration
#
#  tmux 本体由 Homebrew 安装（见 hosts/common/darwin/apps.nix），
#  所以 package = null，这里只托管 ~/.config/tmux/tmux.conf。
#
#  滚轮行为：向上滚直接进 copy-mode，并且以「整页」为单位翻动，
#  而不是 tmux 默认的一次 5 行。
#
#############################################################
{
  programs.tmux = {
    enable = true;
    package = null; # 用 Homebrew 的 tmux

    # 没有 `set -g mouse on` 的话，滚轮事件根本不会交给 tmux 处理
    mouse = true;

    extraConfig = ''
      # ---- 滚轮 = 翻页 ---------------------------------------------------
      # 普通模式下向上滚：
      #   - pane 里跑着全屏程序（vim / less 这类开了 alternate screen 的）
      #     或已经在 copy-mode 里 -> 事件原样转发（send -M）
      #   - 否则进 copy-mode 并立刻翻上一页
      # copy-mode -e：滚回最底部时自动退出 copy-mode
      bind -n WheelUpPane if -F "#{||:#{pane_in_mode},#{mouse_any_flag}}" {
        send -M
      } {
        copy-mode -e
        send -X page-up
      }

      # copy-mode 内部：一格滚轮 = 一整页（覆盖默认的 scroll-up/down 5 行）
      bind -T copy-mode    WheelUpPane   send -X page-up
      bind -T copy-mode    WheelDownPane send -X page-down
      bind -T copy-mode-vi WheelUpPane   send -X page-up
      bind -T copy-mode-vi WheelDownPane send -X page-down
    '';
  };
}
