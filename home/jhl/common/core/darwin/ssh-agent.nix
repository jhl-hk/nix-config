{
  config,
  lib,
  ...
}:
#############################################################
#
#  SSH Agent (macOS)
#
#  全部终端共用一个 ssh-agent 实例，密钥按需加载。
#  用 Homebrew 的 OpenSSH（带 YubiKey sk 支持），不是系统自带那个。
#
#  从 ssh.nix 拆出来的：这一段全是 /opt/homebrew 路径，只在 macOS 成立。
#
#############################################################
let
  keys = [config.sshKeys.primary] ++ config.sshKeys.extra;

  # 拼成**单行**再插值。多行插值会把整段 zsh 代码的缩进搞乱：
  # Nix 的 '' 字符串按所有行的最小缩进做 de-indent，而以 ${...} 开头
  # 的行如果顶格，最小缩进就变成 0，于是一个空格都不脱，生成的
  # .zshrc 里整块代码都带着 4 空格缩进。
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

    # 固定 socket 路径，重启后仍然可用，root 也能访问
    SSH_AUTH_SOCK="$HOME/.ssh/ssh-agent.sock"
    export SSH_AUTH_SOCK

    _ssh_agent_start() {
      if [ -S "$SSH_AUTH_SOCK" ]; then
        # `ssh-add -l` 只有在联系不上 agent 时才退 2；agent 活着但没装
        # 密钥时退的是 1。只判断成功的话，会把「活着但空」的 agent 当成
        # 死的，于是每开一个新 shell 都杀掉 socket 重起一个。所以判 != 2。
        $NIX_SSH_ADD -l >/dev/null 2>&1
        if [ $? -ne 2 ]; then
          return 0
        fi
      fi

      [ -e "$SSH_AUTH_SOCK" ] && rm -f "$SSH_AUTH_SOCK"

      $NIX_SSH_AGENT -a "$SSH_AUTH_SOCK" -s >/dev/null
      chmod 600 "$SSH_AUTH_SOCK"
    }

    # 密钥懒加载：第一次真的要用的时候才装
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
