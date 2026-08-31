{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
#############################################################
#
#  Claude Code Configuration
#
#  Two halves, split by whether a thing carries hooks.
#
#  Skills are linked one at a time from claude/skills/<name> in this repo and
#  from flake inputs, into ~/.claude/skills/<name>. Linking per skill rather
#  than taking over the directory means manually installed skills coexist.
#  pi reads the same directory (see ./pi.nix), so both harnesses see them.
#
#  Plugins are declared by merging two keys into ~/.claude/settings.json at
#  activation time. Only hook-carrying plugins remain plugins -- see the
#  comment above `marketplaces` below for why, and for what that costs.
#
#  CLAUDE.md and memory stay out of nix entirely: home.file produces read-only
#  store symlinks and Claude Code writes those files itself. settings.json is
#  the same, which is why it is merged rather than linked.
#
#############################################################
let
  # Skills to deploy -- each maps to claude/skills/<name>/SKILL.md
  #
  # pi reads the same directory (see home/jhl/common/core/pi.nix), so anything
  # added here shows up in both harnesses.
  skills = [
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
  #
  # Public inputs land here too, for a different reason: a plugin that carries
  # no hooks is only a bag of skill directories, and linking them is strictly
  # better than letting `claude plugin install` re-clone HEAD at runtime --
  # flake.lock pins the version and a fresh machine needs no network for them.
  # Enumerate every skill directory under a path, keyed by directory name.
  #
  # The predicate is "contains a SKILL.md", not "is a directory": a repo can
  # grow a .github or a scripts/ next to its skills, and linking one of those
  # into ~/.claude/skills would be a silently broken entry rather than an
  # error. Directories are the only candidates; readDir also reports the
  # repo's loose files.
  scanSkills = base:
    lib.mapAttrs (name: _: "${base}/${name}")
    (lib.filterAttrs
      (name: type: type == "directory" && builtins.pathExists "${base}/${name}/SKILL.md")
      (builtins.readDir base));

  inputSkills =
    # Scanned, not listed. These are this org's own multi-skill repos, so
    # anything added upstream is wanted here by definition -- and listing each
    # path by hand meant a skill could sit unlinked indefinitely with nothing
    # to signal it. That is exactly what happened: the repo reached seven
    # entries while this file still named one.
    #
    # `nix flake update jianyuelab-skills` is now the whole workflow.
    scanSkills "${inputs.jianyuelab-skills}"
    // scanSkills "${inputs.jianyuelab-docs}/skills"
    # emilkowalski/skills, scanned for the same reason: it is a single-purpose
    # library (animation and interface-design taste) where every skill is
    # wanted, and apple-design here replaces the hand-copied vendored version
    # that used to sit in claude/skills/.
    // scanSkills "${inputs.emil-skills}/skills"
    // {
      # Anthropic's repo stays explicit. It holds 19 skills and only these four
      # are wanted -- scanning it would quietly enable academy-guide,
      # discernment-nudge and the rest. This list mirrors the "skills" array of
      # the document-skills entry in its marketplace.json.
      #
      # They shell out to pandoc/pdftotext/qpdf and, through uv, to openpyxl,
      # pandas, pypdf and markitdown. Those brews sit in
      # hosts/common/core/darwin/apps.nix rather than dev-extras.nix precisely
      # because this list is fleet-wide: a skill offered on a machine that
      # cannot run it fails mid-task with a shell error instead of simply not
      # being there.
      docx = "${inputs.anthropic-skills}/skills/docx";
      pdf = "${inputs.anthropic-skills}/skills/pdf";
      pptx = "${inputs.anthropic-skills}/skills/pptx";
      xlsx = "${inputs.anthropic-skills}/skills/xlsx";
    };

  # -- Plugins ------------------------------------------------------------
  #
  # Only plugins that carry hooks stay plugins; anything else becomes an entry
  # in inputSkills above. Hooks are the dividing line because there is no way
  # to express one through home.file, and for these three the hook *is* the
  # feature:
  #
  #   claude-code-wakatime  heartbeats
  #   jyl-usage             the five hooks that read the transcript
  #   superpowers           a SessionStart hook that injects the whole
  #                         using-superpowers SKILL.md into context. Dropping
  #                         it would leave the 14 skills present but unadvertised
  #
  # What nix owns is the *declaration* -- which marketplaces exist and which
  # plugins are on. Claude Code still clones the content into
  # ~/.claude/plugins/cache at runtime, so these are not version-pinned the
  # way inputSkills is. That is the cost of keeping the hooks.
  marketplaces = {
    wakatime.source = {
      source = "git";
      url = "https://github.com/wakatime/claude-code-wakatime.git";
    };
    jianyuelab-claude.source = {
      source = "github";
      repo = "JianyueLab/claude-plugin";
    };
    superpowers-dev.source = {
      source = "git";
      url = "https://github.com/obra/superpowers.git";
    };
  };

  enabledPlugins = {
    "claude-code-wakatime@wakatime" = true;
    "jyl-usage@jianyuelab-claude" = true;
    "superpowers@superpowers-dev" = true;
  };

  settingsPath = "${config.home.homeDirectory}/.claude/settings.json";
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
    inputSkills;

  # settings.json cannot be a home.file: Claude Code writes theme, effortLevel,
  # autoMode and tui back into it, and a store symlink is read-only. So nix
  # merges its two keys in at activation time instead and leaves the rest of
  # the file alone.
  #
  # The merge is **additive** (`+`), not authoritative: an entry added by hand
  # with `claude plugin install` survives the next switch rather than being
  # reverted. That matches how skills are linked one at a time above -- nix
  # states what must be present, not what must be absent. The flip side is
  # that removing a plugin here does *not* uninstall it; run
  # `claude plugin uninstall <name>@<marketplace>` for that.
  home.activation.claudePlugins = lib.hm.dag.entryAfter ["writeBoundary"] ''
    settings="${settingsPath}"

    # home-manager marks DRY_RUN_CMD deprecated and gates on DRY_RUN itself.
    # Prefixing would also be wrong here: $DRY_RUN_CMD neutralises the command
    # but never the redirection, so `$DRY_RUN_CMD echo '{}' > "$f"` writes the
    # literal text `echo {}` into the file on a dry run. Gate the whole block.
    if [[ -v DRY_RUN ]]; then
      echo "claude.nix: would merge plugin keys into $settings"
    else
      mkdir -p "$(dirname "$settings")"
      [ -s "$settings" ] || echo '{}' > "$settings"

      if ! ${pkgs.jq}/bin/jq -e . "$settings" >/dev/null 2>&1; then
        echo "claude.nix: $settings is not valid JSON, skipping plugin merge" >&2
      elif ${pkgs.jq}/bin/jq \
        --argjson m ${lib.escapeShellArg (builtins.toJSON marketplaces)} \
        --argjson p ${lib.escapeShellArg (builtins.toJSON enabledPlugins)} \
        '.extraKnownMarketplaces = ((.extraKnownMarketplaces // {}) + $m)
         | .enabledPlugins = ((.enabledPlugins // {}) + $p)' \
        "$settings" > "$settings.nix-tmp"; then
        mv "$settings.nix-tmp" "$settings"
      else
        rm -f "$settings.nix-tmp"
        echo "claude.nix: jq merge failed, left $settings untouched" >&2
      fi
    fi
  '';
}
