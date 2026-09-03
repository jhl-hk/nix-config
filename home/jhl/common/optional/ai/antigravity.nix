{pkgs, ...}:
#############################################################
#
#  Antigravity (agy) -- skills only
#
#  Points Antigravity at ~/.claude/skills rather than giving it a second copy
#  of every skill. It implements the same Agent Skills standard -- a directory
#  per skill holding a SKILL.md with name/description frontmatter -- and its
#  own customization docs describe skills.json as the supported way to register
#  customizations kept outside the default discovery locations. One entry buys
#  the whole set, including skills installed by hand.
#
#  The discovery path would otherwise be ~/.gemini/config/skills/<name>/, i.e.
#  what claude.nix builds for ~/.claude/skills. Repeating that here would mean
#  a second set of links to maintain and a second place to forget to add one;
#  this is the same trade pi.nix records, for the same reason.
#
#  Reach is deliberately identical to pi's: ~/.claude/skills only. Skills that
#  arrive through a Claude Code *plugin* -- superpowers above all -- live under
#  ~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/skills instead, and
#  are not covered. That path carries a version Claude Code bumps at runtime,
#  so naming it here would silently break on the next plugin update.
#
#  Optional rather than core because agy is a cask carried only by the two
#  desktop machines (hosts/common/optional/darwin/dev-extras.nix). Writing this
#  on a host without the binary is exactly the inconsistency opencode.nix had
#  before its brew moved to core: a fully configured agent and nothing to run.
#
#############################################################
{
  # Safe as a read-only store symlink, unlike its neighbours in
  # ~/.gemini/config/: config.json and mcp_config.json are written back by the
  # app, but skills.json is user-authored -- the docs present it as a file you
  # write and commit, and nothing in Antigravity updates it.
  home.file.".gemini/config/skills.json".source = (pkgs.formats.json {}).generate "agy-skills.json" {
    # ~ is expanded by Antigravity, the same as pi's skills entry.
    entries = [{path = "~/.claude/skills";}];
  };
}
