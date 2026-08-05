{lib, ...}:
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
#############################################################
let
  # Skills to deploy -- each maps to claude/skills/<name>/SKILL.md
  skills = [
    "nix-config"
  ];
in {
  home.file = lib.listToAttrs (
    map (
      name:
        lib.nameValuePair ".claude/skills/${name}" {
          source = lib.custom.relativeToRoot "claude/skills/${name}";
        }
    )
    skills
  );
}
