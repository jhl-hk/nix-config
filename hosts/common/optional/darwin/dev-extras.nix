{...}:
#############################################################
#
#  The rest of the CLI toolbox
#
#  Split out of hosts/common/core/darwin/apps.nix. These are real tools that
#  are simply not needed on every machine: language toolchains, the Kubernetes
#  and cloud CLIs, packet-level networking, and the document converters the
#  docx/pdf/pptx/xlsx skills shell out to.
#
#  Imported by jhlsMacBookPro and SeandeMac-Studio. jhlsMacBookAir does not
#  import it and keeps the ~14 brews in core.
#
#  siderolabs/tap travels with talosctl rather than living in core, so a
#  machine that declines this file does not carry a tap it never uses.
#
#############################################################
{
  darwinHomebrew = {
    taps = [
      {
        name = "siderolabs/tap";
        trusted = true;
      }
    ];

    brews = [
      "gcc" # Fortran
      "go" # Golang
      "openjdk"
      "rust"
      "wails"
      "talosctl"
      "kubernetes-cli"
      "helm"
      "tokei"
      "kubelogin"
      "iperf3"
      "nexttrace"
      "sleuthkit"
      "mole" # Disk cleaner
      "awscli" # AWS CLI
      "rclone"
      "cloudflare-wrangler" # Cloudflare Workers/R2 CLI
      "gemini-cli"
      "opencode"
    ];
  };
}
