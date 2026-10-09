{pkgs, ...}:
#############################################################
#
#  Development toolset -- NixOS
#
#  The Linux counterpart of the Homebrew baseline
#  (hosts/common/core/darwin/apps.nix) plus dev-extras.nix.
#  Mac-only entries (mas, xcodes, ssh-askpass, YubiKey tools, mole,
#  harness, antigravity-cli) are left out.
#
#  tmux and opencode are installed here because their home-manager
#  modules set package = null and expect Homebrew to provide them.
#
#############################################################
{
  environment.systemPackages = with pkgs; [
    # Baseline
    bun
    nodejs
    just
    tree
    inetutils # telnet
    gh
    tea
    tmux
    pandoc
    qpdf
    poppler-utils
    uv
    python3
    gnumake
    ripgrep
    fd
    jq

    # Coding agents
    claude-code
    codex
    opencode

    # Toolchains
    gcc
    go
    jdk
    rustc
    cargo
    rust-analyzer
    wails

    # Cluster and cloud
    talosctl
    kubectl
    kubernetes-helm
    kubelogin-oidc
    awscli2
    rclone
    wrangler

    # Misc
    tokei
    iperf3
    nexttrace
    sleuthkit
  ];
}
