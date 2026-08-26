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
  #
  # Public inputs land here too, for a different reason: a plugin that carries
  # no hooks is only a bag of skill directories, and linking them is strictly
  # better than letting `claude plugin install` re-clone HEAD at runtime --
  # flake.lock pins the version and a fresh machine needs no network for them.
  inputSkills = {
    web-account-sdk = "${inputs.jianyuelab-skills}/web-account-sdk";
    jianyuelab-docs = "${inputs.jianyuelab-docs}/skills/jianyuelab-docs";

    # The four document-processing skills, replacing the document-skills
    # plugin. This list mirrors the "skills" array of that plugin's entry in
    # the upstream marketplace.json -- the repo holds 19 skills and the plugin
    # exposed only these, so linking the whole skills/ directory would quietly
    # enable things (academy-guide, discernment-nudge) that were never chosen.
    #
    # They shell out to pandoc/soffice/pdftotext/qpdf and the openpyxl,
    # python-docx, python-pptx and pypdf modules. None of that is installed,
    # so these are inert until it is -- see hosts/common/core/darwin/apps.nix.
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
    $DRY_RUN_CMD mkdir -p "$(dirname "$settings")"
    [ -s "$settings" ] || $DRY_RUN_CMD echo '{}' > "$settings"

    # A hand-edited settings.json that does not parse would otherwise be
    # replaced by jq's failure output; bail and let the user fix it.
    if ! ${pkgs.jq}/bin/jq -e . "$settings" >/dev/null 2>&1; then
      echo "claude.nix: $settings is not valid JSON, skipping plugin merge" >&2
    else
      $DRY_RUN_CMD ${pkgs.jq}/bin/jq \
        --argjson m ${lib.escapeShellArg (builtins.toJSON marketplaces)} \
        --argjson p ${lib.escapeShellArg (builtins.toJSON enabledPlugins)} \
        '.extraKnownMarketplaces = ((.extraKnownMarketplaces // {}) + $m)
         | .enabledPlugins = ((.enabledPlugins // {}) + $p)' \
        "$settings" > "$settings.nix-tmp" \
        && $DRY_RUN_CMD mv "$settings.nix-tmp" "$settings"
    fi
  '';
}
