# ==========
# Variables
# ==========

hostname := `hostname`

# ==========
# Recipes
# ==========

# Update to new configuration and switch to new configuration
switch: check
    sudo darwin-rebuild switch --flake .#{{ hostname }}
    @printf '\nSwitched to new config\n'

# Build new configuration but not switch
build:
    sudo darwin-rebuild build --flake .#{{ hostname }}

# Check for errors
check:
    nix flake check --all-systems

# Report whether this machine runs a macOS beta (sets local.macosBeta)
check-beta:
    #!/usr/bin/env bash
    set -euo pipefail
    build=$(sw_vers -buildVersion)
    catalog=$(defaults read /Library/Preferences/com.apple.SoftwareUpdate.plist CatalogURL 2>/dev/null || true)
    printf 'macOS %s (%s)\n' "$(sw_vers -productVersion)" "$build"
    if [[ "$catalog" == *seed* ]]; then
        printf 'beta: yes -- enrolled in a seed catalog\n'
        printf 'set `local.macosBeta = true;` for this host\n'
    else
        printf 'beta: no -- release software update catalog\n'
        printf 'leave `local.macosBeta` unset for this host\n'
    fi

# Update flake inputs and brew packages
update:
    nix flake update
    brew update && brew upgrade

# Clean old generations
clean:
    sudo nix-collect-garbage -d
    mo clean
