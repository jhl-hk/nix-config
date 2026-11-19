{pkgs, ...}:
#############################################################
#
#  Development toolset -- NixOS
#
#  The Linux counterpart of the Homebrew baseline
#  (hosts/common/core/darwin/apps.nix) plus dev-extras.nix.
#  Mac-only entries (mas, xcodes, ssh-askpass, YubiKey tools, mole) are left
#  out.
#
#  tmux is installed here because its home-manager module sets
#  package = null and expects Homebrew to provide it.
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
    forgejo-cli
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
