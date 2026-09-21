{
  lib,
  pkgs,
  ...
}:
#############################################################
#
#  Codex CLI -- skills
#
#  Codex reads ~/.codex/skills/<name>/SKILL.md, the same layout Claude Code
#  uses, and indexes every skill's name and description into the preamble of
#  every request (verified with `codex debug prompt-input`, which renders that
#  preamble as JSON -- the cheapest way to check a skill actually landed).
#  So this file gives Codex the set the rest of the fleet already has.
#
#  -- Mirrored from the directory, not from the nix list -----------------
#
#  The same choice home/jhl/common/optional/ai/harness.nix makes, for the same
#  two reasons. "The skills Claude Code has" is **two** directories: the
#  hand-managed ~/.claude/skills that core/claude.nix links and pi,
#  antigravity and openclaw also read, plus the superpowers plugin's own set
#  under ~/.claude/plugins/cache, which is reachable only by glob because the
#  version segment is whatever is installed. And claude.nix deliberately links
#  per skill rather than owning the directory, so a hand-installed skill sits
#  there too and should come along.
#
#  Reading the directory at activation is therefore strictly closer to "what
#  Claude Code has" than re-deriving the nix list would be.
#
#  -- Symlinks, where harness gets copies --------------------------------
#
#  harness resolves each skill path and rejects anything landing outside its
#  skills directory, which forces a copy. Codex has no such check -- a link
#  through ~/.claude/skills/<name> into the nix store resolves and loads --
#  so this stays symlinks: no duplicated bytes, and a `just rebuild` that
#  repoints a skill repoints Codex's copy at the same moment.
#
#  The links point at the ~/.claude path rather than at the store path they
#  resolve to. That is load-bearing for the cleanup below: "a link into
#  ~/.claude" is exactly the set this file owns, so a skill installed into
#  ~/.codex/skills by hand -- or by Codex's own skill-installer -- is left
#  alone, and only our own stale links are removed.
#
#  .system is untouched. Codex ships imagegen, openai-docs, plugin-creator,
#  skill-creator, skill-installer and review-agent there and rewrites that
#  directory itself on upgrade.
#
#  -- Optional, not core -------------------------------------------------
#
#  The `codex` cask lives in hosts/common/optional/darwin/desktop.nix, so
#  jhlsMacBookAir has no Codex to give skills to. Import this next to
#  hosts/common/optional/darwin/codex.nix, which carries the other half --
#  the gateway and the WakaTime plugin, in the /etc config layer.
#
#############################################################
let
  skillSync = pkgs.writeText "codex-skill-sync.py" ''
    import glob, os, sys

    home, dst = sys.argv[1], sys.argv[2]
    claude = os.path.join(home, ".claude")
    os.makedirs(dst, exist_ok=True)

    sources = [os.path.join(claude, "skills")]
    sources += sorted(glob.glob(os.path.join(claude, "plugins", "cache", "*", "*", "*", "skills")))

    # First source wins: the hand-managed shared set outranks a plugin that
    # happens to ship the same name.
    wanted = {}
    for src in sources:
        if not os.path.isdir(src):
            continue
        for name in sorted(os.listdir(src)):
            d = os.path.join(src, name)
            if name.startswith(".") or name in wanted:
                continue
            if os.path.isfile(os.path.join(d, "SKILL.md")):
                wanted[name] = d

    # Drop what we linked last time and no longer want. Scoped to links into
    # ~/.claude so that .system, Codex's own installs and anything put here by
    # hand survive.
    for name in sorted(os.listdir(dst)):
        p = os.path.join(dst, name)
        if name in wanted or name.startswith(".") or not os.path.islink(p):
            continue
        if os.readlink(p).startswith(claude + os.sep):
            os.unlink(p)

    count = 0
    for name, target in wanted.items():
        p = os.path.join(dst, name)
        if os.path.islink(p):
            if os.readlink(p) == target:
                count += 1
                continue
            os.unlink(p)
        elif os.path.exists(p):
            # A real directory -- installed by hand or by skill-installer.
            continue
        os.symlink(target, p)
        count += 1

    print("codex skills: %d linked from %d source(s)" % (count, len(sources)))
  '';
in {
  # After linkGeneration, not merely after writeBoundary: the source this
  # reads is ~/.claude/skills, which home-manager populates in that step.
  # Both are entryAfter ["writeBoundary"], so without naming it the order
  # between them is unspecified -- and on a fresh machine the wrong order
  # means Codex gets an empty set until the second switch.
  home.activation.codexSkills = lib.hm.dag.entryAfter ["writeBoundary" "linkGeneration"] ''
    dst="$HOME/.codex/skills"

    # home-manager marks DRY_RUN_CMD deprecated and gates on DRY_RUN itself.
    if [[ -v DRY_RUN ]]; then
      echo "codex.nix: would sync skills into $dst"
    else
      ${pkgs.python3}/bin/python3 ${skillSync} "$HOME" "$dst"
    fi
  '';
}
