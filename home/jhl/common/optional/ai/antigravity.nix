{
  config,
  lib,
  pkgs,
  ...
}:
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
    # Absolute, and it has to be. This entry read "~/.claude/skills" for its
    # whole life, on the belief that agy expands ~ the way pi's skills entry
    # does. It does not, and the failure is silent unless you go looking:
    # nothing is printed to the terminal, agy just runs with its two built-in
    # skills and nothing else. It surfaces only in --log-file:
    #
    #   customization.go:415] Failed to resolve absolute path "~/.claude/skills":
    #   ~/.claude/skills must be an absolute path: path is not absolute
    #
    # agy's own bundled docs are what misleads here -- their skills.json
    # example lists `"path": "~/personal-skills"`, which its implementation
    # rejects. Do not "simplify" this back to a tilde.
    #
    # How to re-check after touching this file, since the failure is silent:
    #
    #   agy --log-file /tmp/agy.log -p ok && grep -i skill /tmp/agy.log
    entries = [{path = "${config.home.homeDirectory}/.claude/skills";}];
  };

  # -- Plugin skills -------------------------------------------------------
  #
  # The gap the header describes, now closed. superpowers ships 14 skills that
  # never reach ~/.claude/skills: Claude Code keeps plugin content under
  # ~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/skills, and
  # claude.nix links directories, not plugins.
  #
  # The objection to naming that path was the <version> segment, which Claude
  # Code bumps at runtime. A glob answers it -- this resolves the version at
  # activation time instead of freezing 6.3.0 into the store.
  #
  # Linked into ~/.gemini/config/skills/ rather than added as a second
  # skills.json entry, because that directory is agy's own documented global
  # discovery location ("Global Discovery: ~/.gemini/config/", priority 3 in
  # its bundled customization docs). Pointing an entry at a nix-built
  # directory of symlinks would work equally well; using the native path means
  # the config file stays a one-liner.
  #
  # Deliberately not a glob over every cached plugin. ~/.claude/plugins/cache
  # also holds anthropic-agent-skills/document-skills, 19 skills from a plugin
  # that is *not* in claude.nix's enabledPlugins -- a stale cache Claude Code
  # itself does not load, and whose docx/pdf/pptx/xlsx would collide with the
  # copies claude.nix already links from the anthropic-skills input. Naming the
  # marketplace and plugin keeps this to what is actually enabled.
  #
  # Coupled by hand to claude.nix's enabledPlugins: superpowers is the only one
  # of the three that carries skills rather than hooks. A new skill-carrying
  # plugin needs a line here too.
  home.activation.agyPluginSkills = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [[ -v DRY_RUN ]]; then
      echo "antigravity.nix: would relink plugin skills into ~/.gemini/config/skills"
    else
      dst="${config.home.homeDirectory}/.gemini/config/skills"
      mkdir -p "$dst"

      for s in ${config.home.homeDirectory}/.claude/plugins/cache/superpowers-dev/superpowers/*/skills/*; do
        # A SKILL.md test rather than a directory test, for the reason
        # claude.nix's scanSkills records: a plugin can grow a scripts/ or a
        # .github/ beside its skills, and linking one of those in would be a
        # silently broken entry. The glob not matching at all leaves the
        # literal pattern in $s, which fails this test too -- so an
        # uninstalled plugin is a no-op, not an error.
        [ -f "$s/SKILL.md" ] || continue
        ln -sfn "$s" "$dst/$(basename "$s")"
      done

      # Drop links whose target is gone, so a plugin version bump or an
      # uninstall does not leave agy reading a dangling entry. Only symlinks
      # are considered; a real directory here was put there by hand and is
      # left alone -- the same rule openclaw.nix applies to its own directory.
      for l in "$dst"/*; do
        [ -L "$l" ] || continue
        [ -e "$l" ] || rm -f "$l"
      done
    fi
  '';
}
