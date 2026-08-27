{...}:
#############################################################
#
#  Flyline -- https://github.com/HalFrgrd/flyline
#
#  A Bash *loadable builtin* (a .dylib that Bash dlopen()s) replacing
#  readline with a ratatui-based editor: syntax highlighting, inline
#  suggestions, fuzzy history, mouse support. It is not a shell and not a
#  standalone binary -- nothing happens until an interactive Bash runs
#  `enable -f <path> flyline`. That half lives in
#  home/jhl/common/optional/shell/flyline.nix; this file only puts the
#  library on disk.
#
#  Why brew and not a flake input: upstream does ship a flake
#  (packages.aarch64-darwin.flyline), but its only module output is a
#  *nixosModule* with the .so path hard-coded, and the package builds the
#  whole Rust tree from source with no binary cache. homebrew-core carries
#  it with an arm64 bottle, which is also how the rest of this fleet's CLI
#  tooling arrives (bun, go, just, ...). Version therefore floats with
#  `just update` rather than being pinned by flake.lock.
#
#  Installed path -- the formula does
#    (lib/"bash").install shared_library("target/release/libflyline") => "flyline"
#  so the file is /opt/homebrew/lib/bash/flyline, with no extension. The
#  consumer references that exact path; a formula reorganisation breaks it
#  silently (Bash just prints "cannot open shared object" at startup), so
#  the two files are a pair.
#
#############################################################
{
  # No tap: flyline ships from homebrew/core. tw93/tap used to sit in the
  # fleet-wide list, but nothing declared here or anywhere else consumes it --
  # `brew info --json=v2 flyline` reports tap "homebrew/core", and so does
  # mole, the other plausible candidate. It was dead weight and is now gone.
  darwinHomebrew.brews = ["flyline"];
}
