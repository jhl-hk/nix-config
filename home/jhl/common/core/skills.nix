{
  config,
  inputs,
  lib,
  ...
}:
#############################################################
#
#  Agent skills
#
#  Each skill is linked to ~/.agents/skills/<name>, which omp reads natively.
#  Linked per skill rather than owning the directory, so hand-installed skills
#  coexist.
#
#  Sources:
#    skills/<name>            this repo; own and forked third-party skills.
#                             The writing standard is skills/README.md.
#    jianyuelab-docs input    private repo, so not vendored.
#    JianyueLab/skills        live symlinks into the local checkout.
#
#############################################################
let
  # Every directory under a path that contains a SKILL.md, keyed by name.
  # Directories only: readDir also reports loose files, and a repo can grow a
  # .github or scripts/ next to its skills.
  scanSkills = base:
    lib.mapAttrs (name: _: "${base}/${name}")
    (lib.filterAttrs
      (name: type: type == "directory" && builtins.pathExists "${base}/${name}/SKILL.md")
      (builtins.readDir base));

  repoSkills = scanSkills (lib.custom.relativeToRoot "skills");

  # home.file links a directory source as one symlink into the store. That
  # keeps jianyuelab-docs working: its `docs` entry is a relative git symlink
  # to the repo root, which only resolves inside the input's own store path.
  # Edits need a push and `nix flake update jianyuelab-docs`.
  inputSkills = scanSkills "${inputs.jianyuelab-docs}/skills";

  deployed = repoSkills // inputSkills;

  targets = [".agents/skills"];

  liveSkillsDir = "${config.home.homeDirectory}/Documents/Dev/JianyueLab/skills";
in {
  config.home.file = lib.listToAttrs (lib.concatMap (target:
    lib.mapAttrsToList (name: source: lib.nameValuePair "${target}/${name}" {inherit source;}) deployed)
  targets);

  # JianyueLab/skills: one symlink per skill into the working copy, so an edit
  # to a SKILL.md there is visible immediately. Adding or
  # removing a skill directory still needs a switch.
  #
  # Plain symlinks, not mkOutOfStoreSymlink: the names come from the checkout,
  # which pure evaluation cannot read. A name already managed by home.file is
  # left alone; links into the checkout whose target is gone are removed.
  config.home.activation.liveSkills = lib.hm.dag.entryAfter ["linkGeneration"] ''
    src=${lib.escapeShellArg liveSkillsDir}

    if [[ -v DRY_RUN ]]; then
      echo "skills.nix: would link skills from $src"
    elif [ ! -d "$src" ]; then
      echo "skills.nix: $src not found, skipping live skills" >&2
    else
      for dst in ${lib.concatMapStringsSep " " (t: lib.escapeShellArg "${config.home.homeDirectory}/${t}") targets}; do
        mkdir -p "$dst"
        for link in "$dst"/*; do
          if [ -L "$link" ] && [ ! -e "$link" ]; then
            case "$(readlink "$link")" in "$src"/*) rm "$link" ;; esac
          fi
        done
        for dir in "$src"/*/; do
          dir="''${dir%/}"
          name="$(basename "$dir")"
          [ -f "$dir/SKILL.md" ] || continue
          target="$dst/$name"
          if [ -e "$target" ] || [ -L "$target" ]; then
            case "$(readlink "$target")" in
              "$dir") continue ;;
              "$src"/*) ;;
              *) echo "skills.nix: $target exists, not linking $name" >&2; continue ;;
            esac
          fi
          ln -sfn "$dir" "$target"
        done
      done
    fi
  '';
}
