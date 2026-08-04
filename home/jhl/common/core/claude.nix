{lib, ...}:
#############################################################
#
#  Claude Code Configuration
#
#  只托管 skills：仓库里的 claude/skills/<name> 软链到
#  ~/.claude/skills/<name>，按 skill 逐个链接而不是整目录接管，
#  这样手动装的其它 skill 还能和它们共存。
#
#  settings.json / CLAUDE.md / memory 刻意不纳入 nix：
#  home.file 生成的是指向 nix store 的只读软链，Claude Code
#  自己要回写这些文件，托管了就写不动。
#
#############################################################
let
  # 要部署的 skill —— 对应 claude/skills/<name>/SKILL.md
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
