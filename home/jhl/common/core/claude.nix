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
    "conserving-context"
    # Vendored from github/awesome-copilot rather than taken as an input like
    # every other third-party skill here: that repo is a 105 MiB checkout of
    # 100 Copilot plugins and this is three files inside it. See
    # claude/skills/gdpr-compliant/UPSTREAM.md for the commit, the MIT notice
    # and the two local fixes to re-check when bumping it.
    "gdpr-compliant"
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

  # Same, one level up, for the marketplace layout: plugins/<plugin>/skills/.
  #
  # Flattening is safe because the skill name -- the directory name, which is
  # what lands in ~/.claude/skills -- is what Claude Code addresses; the plugin
  # a skill was filed under is packaging, not identity. A collision between two
  # plugins would silently drop one, so `//` here is the same bet the merge in
  # inputSkills already makes across repos.
  #
  # The `skills` guard is not decorative: these repos carry docs/ and .github/
  # under plugins/ siblings, and readDir reports those too.
  scanMarketplace = base:
    lib.foldl' (acc: name: acc // scanSkills "${base}/plugins/${name}/skills") {}
    (lib.attrNames
      (lib.filterAttrs
        (name: type: type == "directory" && builtins.pathExists "${base}/plugins/${name}/skills")
        (builtins.readDir "${base}/plugins")));

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

  # -- Privacy / compliance, opt-in ------------------------------------------
  #
  # 52 skills across three repos, kept out of the default set for one measured
  # reason: a skill costs its description in the system prompt on **every**
  # turn whether or not it fires. These 52 are ~6k tokens per turn, and an
  # audit of 114 local sessions found not one of them invoked even once.
  #
  # That is a statement about this fleet, not about the skills -- no
  # compliance work happens here. Turn them on with
  # `claudeComplianceSkills.enable = true;` in a host's home file when it
  # does, and they come back exactly as they were.
  #
  # Asymmetric scanning, because the three repos are asymmetric; see the input
  # comments in flake.nix for the sizes involved. grc-skills is scanned whole
  # (33 skills, one per framework -- which one a question needs is not
  # knowable in advance). privacy-skills is scanned **one plugin deep**, not
  # at the repo root: the root holds 283 skills, gdpr-compliance-skills is 18
  # of them and the rest are re-cuts for domains this fleet does not touch.
  # alireza-skills contributes exactly one, which goes past GDPR into German
  # BDSG and carries scripts/ for DPIA generation and DSAR deadline tracking.
  complianceSkills =
    scanMarketplace "${inputs.grc-skills}"
    // scanSkills "${inputs.privacy-skills}/plugins/gdpr-compliance-skills/skills"
    // {
      gdpr-dsgvo-expert = "${inputs.alireza-skills}/ra-qm-team/skills/gdpr-dsgvo-expert";
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
  options.claudeComplianceSkills.enable = lib.mkEnableOption ''
    the privacy/compliance skill set (GDPR, ISO, SOC 2, NIST, HIPAA, ...).
    Off by default: 52 skills that cost their descriptions in the system
    prompt every turn and were invoked zero times across 114 local sessions
  '';

  config.home.file =
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
    (inputSkills
      // lib.optionalAttrs config.claudeComplianceSkills.enable complianceSkills);

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
  config.home.activation.claudePlugins = lib.hm.dag.entryAfter ["writeBoundary"] ''
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
