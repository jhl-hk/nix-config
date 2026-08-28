# ==========
# Variables
# ==========

secrets := "../nix-secrets"

# Every recipe here shells out to `nix`, and on a machine that has not switched
# yet there is nothing enabling flakes: the Macs get experimental-features from
# the /etc/nix/nix.conf nix-darwin generates, and the standalone lane gets it
# from the ~/.config/nix/nix.conf that home-manager writes -- both of which are
# products of a rebuild that cannot run without them. Arch's own nix.conf
# enables neither.
#
# NIX_CONFIG is read as nix.conf content on top of the config files, and the
# extra- prefix appends rather than replaces, so this adds the two features
# without disturbing anything a machine already sets. On an already-switched
# machine it is a no-op.
#
# scripts/rebuild.sh passes --extra-experimental-features itself as well; it is
# meant to work when run directly, not only through just.
export NIX_CONFIG := "extra-experimental-features = nix-command flakes"

# List all recipes by default
default:
    @just --list

# ==========
# Everyday
# ==========

# The three recipes below delegate to scripts/rebuild.sh. It picks the lane by
# uname -- nix-darwin on a Mac, standalone home-manager on Linux -- bootstraps a
# machine that has never switched, and prefers nh when nh is installed. See the
# header of that script.

# Rebuild and switch to the new config
rebuild: rebuild-pre && rebuild-post
    scripts/rebuild.sh switch

# Alias for rebuild; the sysnew alias in zsh uses rebuild
switch: rebuild

# Build without switching
build: rebuild-pre
    scripts/rebuild.sh build

# rebuild with --show-trace, for debugging evaluation errors
rebuild-trace: rebuild-pre && rebuild-post
    scripts/rebuild.sh switch --trace

# rebuild followed by check; use before pushing
rebuild-full: rebuild check

# Update flake inputs, then rebuild
rebuild-update: update rebuild

# Check for evaluation errors
check *ARGS:
    nix flake check --all-systems --show-trace {{ ARGS }}

# diff excluding flake.lock -- input updates are too noisy
diff:
    git diff ':!flake.lock'

# ==========
# rebuild pre/post hooks
# ==========

# Pull the latest secrets and make the flake see new untracked files.
#
# git add --intent-to-add is required: flake source tracking ignores untracked
# files entirely, and intent-to-add lifts them into the index without staging
# their content. Skip this and a newly created .nix file silently has no effect.

# rebuild pre-hook: pull secrets + refresh the LLM model list + let the flake see untracked files
rebuild-pre: update-nix-secrets llm-models-soft
    git add --intent-to-add .

# llm-models as a rebuild step: same fetch, but never fatal.
#
# Run by hand, llm-models is strict on purpose -- a 401 or an empty response
# should stop you and get looked at. As a pre-hook the trade goes the other
# way: being offline, on a machine with no age key yet, or hitting a bad
# gateway must not block a switch. Nothing is lost when it fails, because the
# committed models.json stays exactly where it is -- a valid list, just a
# stale one. Same reasoning as the `|| true` on the rebase in
# update-nix-secrets.
#
# Ordering matters: this runs after update-nix-secrets, so the key it decrypts
# is the one that was just pulled.

# llm-models for rebuild-pre: refresh the model list, but never fail the rebuild
llm-models-soft:
    #!/usr/bin/env bash
    set -uo pipefail
    export JUST_LLM_MODELS_IN_REBUILD=1
    if ! {{ just_executable() }} llm-models; then
        printf '\n⚠️  model list not refreshed, continuing with the committed models.json\n\n'
    fi

# Confirm sops decryption actually succeeded
rebuild-post: check-sops

# Pull nix-secrets and re-lock it.
#
# nix-config treats nix-secrets as a locked remote input, so a local change
# that has not been pushed has no effect. A failed rebase is ignored (a dirty
# work tree should not stop the rebuild).

# Pull nix-secrets and re-lock the flake input
update-nix-secrets:
    #!/usr/bin/env bash
    set -uo pipefail
    if [ -d "{{ secrets }}" ]; then
        git -C "{{ secrets }}" fetch
        git -C "{{ secrets }}" rebase > /dev/null 2>&1 || true
    fi
    nix flake update nix-secrets --timeout 5

# ==========
# Maintenance
# ==========

# Update flake inputs and brew.
#
# Homebrew only exists on the Macs; the Arch machine's system packages are
# pacman's business and deliberately not touched from here.

# Update flake inputs, and brew on macOS
update:
    #!/usr/bin/env bash
    set -euo pipefail
    nix flake update
    if [ "$(uname -s)" = "Darwin" ]; then
        brew update && brew upgrade
    fi

# Clean up old generations
clean:
    #!/usr/bin/env bash
    set -euo pipefail
    sudo nix-collect-garbage -d
    if [ "$(uname -s)" = "Darwin" ]; then
        mo clean
    fi

# Format every .nix file
fmt:
    nix fmt

# Report whether this machine is on a macOS beta (drives darwinHomebrew.macosBeta)
check-beta:
    #!/usr/bin/env bash
    set -euo pipefail
    if [ "$(uname -s)" != "Darwin" ]; then
        echo "not a Mac; darwinHomebrew.macosBeta does not apply here"
        exit 0
    fi
    build=$(sw_vers -buildVersion)
    catalog=$(defaults read /Library/Preferences/com.apple.SoftwareUpdate.plist CatalogURL 2>/dev/null || true)
    printf 'macOS %s (%s)\n' "$(sw_vers -productVersion)" "$build"
    if [[ "$catalog" == *seed* ]]; then
        printf 'beta: yes -- enrolled in a seed catalog\n'
        printf 'set `darwinHomebrew.macosBeta = true;` for this host\n'
    else
        printf 'beta: no -- release software update catalog\n'
        printf 'leave `darwinHomebrew.macosBeta` unset for this host\n'
    fi

# ==========
# Secrets
# ==========

# age-keygen is a second binary inside the age package, so `nix run nixpkgs#age`
# cannot reach it: that runs `age`, which treats "age-keygen" as an input file.
# Hence `nix shell ... --command`.
#
#   just age-key ~/.config/sops/age/keys.txt

# Generate a new age key; with a path it is written to disk and the public key printed, with no argument it goes to stdout (and your scrollback)
age-key OUT="":
    #!/usr/bin/env bash
    set -euo pipefail
    if [ -n "{{ OUT }}" ]; then
        if [ -e "{{ OUT }}" ]; then
            echo "❌ refusing to overwrite existing key: {{ OUT }}" >&2
            exit 1
        fi
        mkdir -p "$(dirname "{{ OUT }}")"
        chmod 700 "$(dirname "{{ OUT }}")"
        nix shell nixpkgs#age --command age-keygen -o "{{ OUT }}"
        chmod 600 "{{ OUT }}"
        echo
        echo "Public key (this is what goes in .sops.yaml):"
        nix shell nixpkgs#age --command age-keygen -y "{{ OUT }}"
    else
        nix shell nixpkgs#age --command age-keygen
    fi

# After editing .sops.yaml, re-encrypt every ciphertext file for the current
# recipient list
rekey:
    #!/usr/bin/env bash
    set -euo pipefail
    cd "{{ secrets }}"
    shopt -s nullglob
    files=(secrets/*.yaml)
    if [ ${#files[@]} -eq 0 ]; then
        echo "No secrets/*.yaml, skipping"
        exit 0
    fi
    for f in "${files[@]}"; do
        echo "updatekeys $f"
        nix run nixpkgs#sops -- updatekeys -y "$f"
    done
    echo
    echo "Remember to commit + push in {{ secrets }}, then run just update-nix-secrets"

# Edit a ciphertext file, e.g. just sops-edit shared
sops-edit FILE:
    #!/usr/bin/env bash
    set -euo pipefail
    export SOPS_AGE_KEY_FILE="${SOPS_AGE_KEY_FILE:-$HOME/.config/sops/age/keys.txt}"
    if [ ! -f "$SOPS_AGE_KEY_FILE" ]; then
        echo "❌ age key not found: $SOPS_AGE_KEY_FILE" >&2
        exit 1
    fi
    # secrets/ does not exist initially, and sops will not create the directory
    mkdir -p "{{ secrets }}/secrets"
    # Run from the nix-secrets root so .sops.yaml creation_rules match correctly
    cd "{{ secrets }}"
    nix run nixpkgs#sops -- "secrets/{{ FILE }}.yaml"
    echo
    echo "After editing: cd {{ secrets }} && git add -A && git commit && git push"
    echo "Then come back: just update-nix-secrets"

# Lightweight post-rebuild check: did every secret this machine declares
# actually land?
#
# sops-install-secrets runs through postActivation, and the activate script uses
# set -e, so a decryption failure aborts the switch with an error -- it is not
# silent. This checks a different thing: that declared secrets really do appear
# under /run/secrets, catching the "configured but not in effect" case.
#
# Skipped outright when no secrets are declared; it does not fake success.
#
# Also skipped on the standalone home-manager lane, which has no system scope
# and therefore no sops.secrets to check. That lane has no machines right now;
# see the standalone-lane note in README.md before putting one back on it.

# Confirm every secret declared on this machine really landed in /run/secrets
check-sops:
    #!/usr/bin/env bash
    set -uo pipefail
    if [ "$(uname -s)" != "Darwin" ]; then
        echo "sops: no system scope on this machine (standalone home-manager), skipping"
        exit 0
    fi
    manifest=$(nix eval --raw ".#darwinConfigurations.$(uname -n).config.sops.secrets" \
                 --apply 's: builtins.concatStringsSep "\n" (builtins.attrNames s)' 2>/dev/null)
    if [ -z "$manifest" ]; then
        echo "sops: this machine declares no secrets, skipping"
        exit 0
    fi
    rc=0
    while IFS= read -r name; do
        [ -z "$name" ] && continue
        if sudo test -s "/run/secrets/$name"; then
            echo "  ✅ /run/secrets/$name"
        else
            echo "  ❌ /run/secrets/$name missing or empty"
            rc=1
        fi
    done <<< "$manifest"
    exit $rc

# Canary self-check: exercise the sops pipeline end to end.
#
# Requires first following the instructions at the top of
# hosts/common/optional/darwin/sops-canary.nix: write canary/value into
# shared.yaml and import that file on this machine.

# End-to-end sops pipeline self-check (set up the canary first, see above)
verify-sops EXPECT="sops-pipeline-ok":
    #!/usr/bin/env bash
    set -uo pipefail

    # The canary exercises sops-nix's *system* path -- postActivation plus the
    # launchd daemon -- neither of which exists on the standalone lane.
    if [ "$(uname -s)" != "Darwin" ]; then
        echo "no system sops on this machine (standalone home-manager), nothing to verify"
        exit 0
    fi

    # Check the preconditions first. If any step is missing, all four checks
    # below are guaranteed to fail red -- but that means "not set up", not
    # "pipeline broken". Keep those two apart.
    missing=0
    if [ ! -f "{{ secrets }}/secrets/shared.yaml" ]; then
        echo "❌ precondition: {{ secrets }}/secrets/shared.yaml does not exist"
        echo "   run: just sops-edit shared      then write:"
        echo "        canary:"
        echo "            value: {{ EXPECT }}"
        echo "   then commit + push in {{ secrets }}"
        missing=1
    fi
    canary_mod="hosts/common/optional/darwin/sops-canary.nix"
    if [ ! -f "$canary_mod" ]; then
        echo "❌ precondition: $canary_mod does not exist (deleted after verifying)"
        echo "   restore it from git history:"
        echo "     p=$canary_mod"
        echo '     git show "$(git rev-list -n1 HEAD -- "$p")^:$p" > "$p"'
        missing=1
    elif ! nix eval --raw ".#darwinConfigurations.$(hostname).config.sops.secrets" \
           --apply 's: builtins.concatStringsSep " " (builtins.attrNames s)' 2>/dev/null \
           | grep -q 'canary/value'; then
        echo "❌ precondition: this machine does not declare canary/value"
        echo "   add a line to the imports in hosts/darwin/$(hostname)/default.nix:"
        echo "        \"$canary_mod\""
        echo "   then run just rebuild"
        missing=1
    fi
    if [ $missing -ne 0 ]; then
        echo
        echo "Preconditions unmet, skipping checks (this does not mean the sops pipeline is broken)"
        exit 1
    fi

    rc=0

    echo "1) raw secret /run/secrets/canary/value"
    if got=$(sudo cat /run/secrets/canary/value 2>/dev/null) && [ "$got" = "{{ EXPECT }}" ]; then
        echo "   ✅ value correct"
    else
        echo "   ❌ read '${got:-<empty>}', expected '{{ EXPECT }}'"
        rc=1
    fi

    echo "2) placeholder substitution in ~/.sops-canary"
    if [ -f "$HOME/.sops-canary" ]; then
        if grep -q "^canary={{ EXPECT }}$" "$HOME/.sops-canary"; then
            echo "   ✅ placeholder substituted"
        else
            echo "   ❌ wrong contents:"
            sed 's/^/      /' "$HOME/.sops-canary"
            rc=1
        fi
    else
        echo "   ❌ file does not exist"
        rc=1
    fi

    echo "3) permissions"
    # sops.templates lands a symlink -> /run/secrets/rendered/<name>, and
    # owner/mode apply to the **target**, so stat -L has to follow it.
    echo "   $HOME/.sops-canary -> $(readlink "$HOME/.sops-canary" 2>/dev/null || echo '(not a symlink)')"
    perm=$(sudo stat -L -f '%Sp %Su' "$HOME/.sops-canary" 2>/dev/null || echo "? ?")
    if [ "$perm" = "-rw------- $USER" ]; then
        echo "   ✅ target permissions $perm"
    else
        echo "   ❌ target permissions $perm, expected -rw------- $USER"
        rc=1
    fi

    echo "4) boot path (launchd daemon, a different path from the switch one)"
    sudo launchctl kickstart -k system/org.nixos.sops-install-secrets 2>&1 | sed 's/^/   /'
    sleep 1
    if sudo test -s /run/secrets/canary/value; then
        echo "   ✅ secret still present after re-run"
    else
        echo "   ❌ secret gone after re-run -- it will break on reboot"
        rc=1
    fi

    echo
    [ $rc -eq 0 ] && echo "sops pipeline passes end to end" || echo "sops pipeline has a problem, see the ❌ above"
    exit $rc

# ==========
# LLM
# ==========

# Refresh the LLM model list: hit /v1/models, write
# home/jhl/common/core/llm/models.json
#
# Why this step exists: flake evaluation has no network, and that endpoint needs
# a key anyway (a bare GET returns 401), so the model list cannot be fetched at
# build time. Generating a file and readFile-ing it keeps the list declarative
# -- in git, diffable, revertable.
#
# The key is decrypted straight from the ciphertext rather than read from
# /run/secrets, so no rebuild is needed first.
#
# rebuild-pre already runs this on every switch (via llm-models-soft). Running
# it by hand is for seeing the full list, or for getting the real error when
# the automatic refresh is only warning.

# Refresh the LLM model list from /v1/models into llm/models.json
# Refresh one gateway's model list. Both providers in home/jhl/common/core/llm.nix
# are fed this way; SECRET is the sops key under shared.yaml, HOST the gateway.
llm-models-one SECRET HOST OUT:
    #!/usr/bin/env bash
    set -euo pipefail
    out="{{ OUT }}"
    export SOPS_AGE_KEY_FILE="${SOPS_AGE_KEY_FILE:-$HOME/.config/sops/age/keys.txt}"

    if [ ! -f "{{ secrets }}/secrets/shared.yaml" ]; then
        echo "❌ {{ secrets }}/secrets/shared.yaml not found; run just sops-edit shared first" >&2
        exit 1
    fi

    key=$(nix run nixpkgs#sops -- -d --extract '["{{ SECRET }}"]["api_key"]' \
        "{{ secrets }}/secrets/shared.yaml" 2>/dev/null || true)
    if [ -z "$key" ]; then
        echo "❌ shared.yaml has no {{ SECRET }}.api_key; run just sops-edit shared first" >&2
        exit 1
    fi

    url="https://{{ HOST }}/v1/models"
    echo "GET $url"
    body=$(curl -sS --fail-with-body --max-time 30 -H "Authorization: Bearer $key" "$url") || {
        echo "❌ fetch failed; the server response is above" >&2
        exit 1
    }

    # Take ids only, sorted and deduplicated. One per line, for readable diffs.
    printf '%s' "$body" \
        | nix run nixpkgs#jq -- -S '[.data[].id] | unique' > "$out.tmp"

    n=$(nix run nixpkgs#jq -- 'length' < "$out.tmp")
    if [ "$n" -eq 0 ]; then
        echo "❌ endpoint returned 0 models; not overwriting the existing $out" >&2
        rm -f "$out.tmp"
        exit 1
    fi

    mv "$out.tmp" "$out"
    echo "✅ $n models -> $out"

# Refresh every gateway's model list
llm-models: (llm-models-one "llm" "llm.jianyuelab.net" "home/jhl/common/core/llm/models.json") (llm-models-one "llm_api" "llm-api.jianyuelab.net" "home/jhl/common/core/llm/models-api.json")

    # Called from rebuild-pre (llm-models-soft), the full listing is a wall of
    # text in the middle of a switch and "Next: just rebuild" is wrong -- the
    # rebuild is already happening. Standalone, both are the point.
    if [ -z "${JUST_LLM_MODELS_IN_REBUILD:-}" ]; then
        nix run nixpkgs#jq -- -r '.[]' < "$out" | sed 's/^/   /'
        echo
        echo "Next: just rebuild"
    fi
