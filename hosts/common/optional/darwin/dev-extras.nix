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
      # JianyueLab's **private** tap, carrying one formula: harness, below.
      # Separate from the public JianyueLab/homebrew-tap because its formulae
      # point at private source repos, which a public tap cannot install.
      #
      # trusted = true is load-bearing, not boilerplate. Since Homebrew 6.0 an
      # untrusted third-party tap fails to load with `invalid syntax in tap!`
      # -- a misleading message for what is really a trust refusal. The option
      # emits `trusted: true` into the Brewfile so a new machine needs no
      # manual `brew trust`.
      #
      # Both this tap and the source repo are cloned over the machine's own
      # git credentials (osxkeychain or SSH key). There is nothing to configure
      # here, but a machine whose GitHub account cannot read JianyueLab/harness
      # fails the clone -- and brew bundle failing fails the whole activation,
      # not just this formula. That is the cost of the private lane.
      {
        name = "JianyueLab/internal";
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

      # JianyueLab's own CLI coding agent, from the private tap above.
      #
      # Fully qualified rather than a bare "harness": the tap is declared in
      # the same Brewfile so brew would resolve it either way, but the bare
      # name would silently start resolving to homebrew-core the day a formula
      # of that name lands there.
      #
      # It belongs in this file rather than core for a concrete reason beyond
      # the usual one: the formula is `depends_on "go" => :build` and builds
      # from source -- no bottle, because Homebrew cannot fetch release assets
      # from a private repo. The Go toolchain it needs is the "go" brew four
      # lines up, which jhlsMacBookAir does not carry. Putting harness in core
      # would pull a full Go toolchain onto the one machine kept deliberately
      # at ~14 brews, and cleanup = "zap" would then churn it in and out on
      # every switch, since a build-only dep is not a dependency of anything
      # the Brewfile lists.
      "JianyueLab/internal/harness"
    ];

    # agy, the Antigravity CLI agent, replacing gemini-cli here. A cask and
    # not a formula -- Homebrew ships it as an app bundle with a symlinked
    # binary, so `brew info --formula antigravity-cli` finds nothing. Distinct
    # from the "antigravity" cask in desktop.nix, which is the GUI IDE; these
    # are two packages and installing one does not bring the other.
    #
    # home/jhl/common/optional/ai/antigravity.nix wires its skills and is
    # imported by the same two hosts, so the binary and its config travel
    # together.
    casks = ["antigravity-cli"];
  };
}
