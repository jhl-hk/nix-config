{
  inputs,
  lib,
  ...
}:
#############################################################
#
#  Claude Code Configuration
#
#  Manages skills only: claude/skills/<name> in the repo is symlinked to
#  ~/.claude/skills/<name>, linked one skill at a time rather than taking over
#  the whole directory, so manually installed skills can coexist.
#
#  settings.json / CLAUDE.md / memory are deliberately left out of nix:
#  home.file produces read-only symlinks into the nix store, and Claude Code
#  writes those files back itself, which it could not do once managed.
#
#  Plugins land in that same unmanaged half -- `claude plugin i` records the
#  marketplace and the enabled flag in settings.json. Installed here:
#
#    claude plugin marketplace add https://github.com/wakatime/claude-code-wakatime.git
#    claude plugin i claude-code-wakatime@wakatime
#
#  It shells out to wakatime-cli like every other WakaTime consumer, so its
#  config and API key come from home/jhl/common/core/wakatime.nix -- nothing
#  extra to set up after installing.
#
#    claude plugin marketplace add JianyueLab/claude-plugin
#    claude plugin i jyl-usage@jianyuelab-claude
#
#  Reports token usage to the llm-web portal, closing the gap where a
#  subscription-billed Claude Code session is invisible to the gateway's meter.
#  Its two config values come from home/jhl/common/core/jyl-usage.nix, which
#  reuses the llm/api_key secret rather than adding one. That marketplace is a
#  **private** repo, so the clone needs a working GitHub credential.
#
#############################################################
let
  # Skills to deploy -- each maps to claude/skills/<name>/SKILL.md
  #
  # pi reads the same directory (see home/jhl/common/core/pi.nix), so anything
  # added here shows up in both harnesses.
  #
  # apple-design is vendored, not written here: it comes from
  # https://github.com/emilkowalski/skills (MIT, LICENSE kept beside it).
  # Update it by copying the file again -- there is no upstream tracking.
  skills = [
    "apple-design"
    "nix-config"
    "rir-apis"
  ];

  # Skills that cannot be vendored, because this repo is public and they are
  # not. The value is a path inside a private flake input -- see the block
  # above jianyuelab-skills in flake.nix for why, and for the re-locking step
  # that a local edit needs before it is visible here.
  #
  # home.file links a directory source as **one symlink** to the store rather
  # than recreating the tree, which is what keeps jianyuelab-docs working: its
  # `docs` entry is a relative git symlink out to the repo root, and it only
  # resolves while the link points into the input's own store path.
  privateSkills = {
    web-account-sdk = "${inputs.jianyuelab-skills}/web-account-sdk";
    jianyuelab-docs = "${inputs.jianyuelab-docs}/skills/jianyuelab-docs";
  };
in {
  home.file =
    lib.listToAttrs (
      map (
        name:
          lib.nameValuePair ".claude/skills/${name}" {
            source = lib.custom.relativeToRoot "claude/skills/${name}";
          }
      )
      skills
    )
    // lib.mapAttrs' (
      name: source:
        lib.nameValuePair ".claude/skills/${name}" {inherit source;}
    )
    privateSkills;
}
