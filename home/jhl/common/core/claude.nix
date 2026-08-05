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
#############################################################
let
  # Skills to deploy -- each maps to claude/skills/<name>/SKILL.md
  skills = [
    "nix-config"
    "rir-apis"
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
