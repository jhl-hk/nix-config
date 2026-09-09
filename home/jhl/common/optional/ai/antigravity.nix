{
  config,
  inputs,
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
let
  # The antigravity-cli cask from hosts/common/optional/darwin/dev-extras.nix.
  # Spelled out rather than resolved through PATH: an activation script does
  # not get the interactive shell's PATH, so /opt/homebrew/bin is not on it.
  # Same reasoning, and same shape, as openclawBin in ./openclaw.nix.
  agyBin = "/opt/homebrew/bin/agy";
in {
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

  # -- jyl-usage -----------------------------------------------------------
  #
  # Reports agy's token spend to the llm-web portal. agy burns a Google
  # subscription that never crosses the gateway's /v1 proxy, so without this
  # none of it appears in the portal beside the metered traffic -- the same
  # gap the plugin already closes for Claude Code, which claude.nix declares
  # as a marketplace entry.
  #
  # An activation script rather than a file, because there is nothing
  # declarative to write. `agy plugin install` does real work: it converts
  # commands into skills and registers hooks, then records the result in
  # ~/.gemini/config/import_manifest.json. Dropping a copy into
  # ~/.gemini/config/plugins/ by hand is **not** equivalent and does not
  # register.
  #
  # Installed from the flake input, not from the working copy at
  # ~/Documents/Dev/JianyueLab/claude-plugin. The clone is unmanaged user
  # state that need not exist on a given machine, and pinning through
  # flake.lock is what makes SeandeMac-Studio get the same commit as this one.
  # Verified that a read-only source works -- install copies out of it, so a
  # store path is a legal target.
  #
  # -- Why the stamp file --------------------------------------------------
  #
  # The installer takes a full snapshot copy of the source and, per upstream's
  # own design notes, a later change to the source is invisible until it is
  # re-run. Re-running is safe and idempotent, but it copies the whole tree,
  # so doing it on every switch would be pure waste. The stamp records which
  # store path is currently installed; a lock bump changes the path and
  # triggers exactly one reinstall.
  #
  # Delete the stamp to force a reinstall.
  #
  # The stamp alone is not enough to decide, which is why the condition below
  # checks the install itself as well. Something emptied
  # ~/.gemini/config/plugins/ and reset import_manifest.json to
  # {"imports": null} on 2026-09-09 -- cause never identified. A stamp-only
  # test would have read that as "already installed from this store path" and
  # skipped, leaving the plugin gone until the next lock bump. Requiring the
  # installed plugin.json to exist as well means a switch repairs it.
  #
  # -- What this does not manage ------------------------------------------
  #
  # The credentials. The reporter reads JYL_USAGE_BASE_URL and JYL_API_KEY
  # from the environment, exported into zsh by
  # home/jhl/common/core/jyl-usage.nix, which is core and so reaches every
  # machine. agy is a CLI started from a terminal, so its hooks inherit the
  # shell's environment and that is the whole story -- there is no
  # Dock-launched case to cover here, unlike Zed in ./llm.nix.
  #
  # Worth knowing anyway: the reporter is inert **and silent** when it has no
  # key, so absence of errors is not evidence it works. Read the log:
  #
  #   tail -1 ~/.gemini/jyl-usage/log
  #
  # A run that worked reads "N accepted"; "spooled" means it could not upload.
  home.activation.agyJylUsage = lib.hm.dag.entryAfter ["writeBoundary"] ''
    src="${inputs.jianyuelab-plugins}"
    stamp="${config.home.homeDirectory}/.local/state/agy-jyl-usage.nixsrc"
    installed="${config.home.homeDirectory}/.gemini/config/plugins/jyl-usage/plugin.json"

    if [[ -v DRY_RUN ]]; then
      echo "antigravity.nix: would install jyl-usage into agy from $src"
    elif [ ! -x ${agyBin} ]; then
      # The binary is the antigravity-cli cask in dev-extras.nix. A machine
      # that imports this file but has not yet run the Homebrew half is a
      # normal intermediate state, not an error.
      echo "antigravity.nix: ${agyBin} is not installed, skipping jyl-usage" >&2
    elif [ "$(cat "$stamp" 2>/dev/null)" = "$src" ] && [ -f "$installed" ]; then
      : # installed from this exact store path, and still present
    elif ${agyBin} plugin install "$src" >/dev/null 2>&1; then
      mkdir -p "$(dirname "$stamp")"
      echo "$src" > "$stamp"
      echo "antigravity.nix: installed jyl-usage into agy"
    else
      # Deliberately not fatal. A failed plugin install should not take a
      # whole switch down with it -- the stamp stays unwritten, so the next
      # activation retries rather than silently considering it done.
      echo "antigravity.nix: 'agy plugin install' failed, jyl-usage not installed" >&2
    fi
  '';
}
