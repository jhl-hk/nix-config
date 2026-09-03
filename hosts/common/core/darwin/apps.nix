{...}:
#############################################################
#
#  Homebrew manifest -- the baseline every Mac gets
#
#  Data only. The wiring, and the beta gate on masApps, live in
#  modules/hosts/darwin/homebrew/.
#
#  What stays here is what a machine needs to be a usable development box over
#  ssh: a shell, git, the two package managers, and the YubiKey/askpass pair
#  that makes authentication work at all. Everything heavier was split out so
#  a minimal machine can decline it:
#
#    hosts/common/optional/darwin/desktop.nix     GUI apps + Mac App Store
#    hosts/common/optional/darwin/dev-extras.nix  the rest of the CLI toolbox
#
#  jhlsMacBookAir imports neither, which is the whole point of the split --
#  core is what every machine gets, so anything one machine can live without
#  does not belong in it.
#
#  taps / brews / casks are listOf, so definitions from other modules
#  concatenate -- which is how each optional appends its own. Each tap now
#  sits with the formula that needs it rather than all of them living here.
#
#############################################################
{
  darwinHomebrew = {
    taps = [
      {
        name = "oven-sh/bun";
        trusted = true;
      }
      {
        name = "theseal/ssh-askpass";
        trusted = true;
      }
    ];

    # The only two GUI apps in core. Both are infrastructure rather than
    # applications, which is why they are not in desktop.nix:
    #
    #   tailscale-app  is how the other machines are reached at all. Leaving it
    #                  to desktop.nix meant jhlsMacBookAir declined it, and with
    #                  onActivation.cleanup = "zap" the first successful
    #                  activation there would have uninstalled Tailscale and
    #                  cut the ssh route being used to run that very rebuild.
    #   ghostty        pairs with the ghostty-bin.terminfo in ./default.nix's
    #                  systemPackages -- the terminfo is what makes sshing
    #                  *into* a machine from Ghostty work, and it is already
    #                  fleet-wide, so the terminal itself belongs beside it.
    casks = [
      "ghostty"
      "tailscale-app"
    ];

    brews = [
      "bun" # Package manager
      "node"
      "git"
      "just"
      "openssh"
      "tree"
      "telnet"
      "mas"
      "gh"
      "tmux"
      "xcodes"
      "age-plugin-yubikey"
      "ssh-askpass"
      "ykman"

      # In core for the same reason as the block below, and it got there the
      # same way: home/jhl/common/core/opencode.nix generates
      # ~/.config/opencode/opencode.json on every machine, so while this brew
      # sat in dev-extras.nix jhlsMacBookAir carried a fully configured agent
      # with no binary to run it. A fleet-wide config needs a fleet-wide tool.
      #
      # Homebrew rather than nixpkgs is deliberate -- see the "Why not
      # programs.opencode" section in that file for what a nix copy breaks.
      "opencode"

      # Backing tools for the docx/pdf/pptx/xlsx skills, which
      # home/jhl/common/core/claude.nix links on every machine. In core rather
      # than dev-extras.nix for exactly that reason: the skills are fleet-wide,
      # so tools that only some machines have would make them advertise
      # capabilities they cannot deliver -- and the failure surfaces as a
      # confusing shell error mid-task, not as a missing skill.
      #
      #   pandoc   docx -> markdown, the "read a Word file" path
      #   qpdf     command-line merge/split/rotate/encrypt
      #   poppler  provides pdftotext
      #
      # uv is the odd one out and the reason there is no python3.withPackages
      # anywhere: the skills need openpyxl, pandas, pypdf and markitdown, all
      # of which nixpkgs has -- but home/jhl/common/core/darwin/darwin.nix
      # prepends /opt/homebrew/bin to PATH, so a nix python would never win a
      # bare `python3` lookup. Shadowing Homebrew's python@3.14 is not an
      # option either: awscli, openssh, ykman and ldns all depend on it. So the
      # modules are fetched per-invocation instead:
      #
      #   uv run --with openpyxl,pandas python script.py
      #   uvx markitdown deck.pptx
      "pandoc"
      "qpdf"
      "poppler"
      "uv"
    ];
  };
}
