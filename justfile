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

# Update flake inputs and brew packages
update:
    nix flake update
    brew update && brew upgrade

# Clean old generations
clean:
    sudo nix-collect-garbage -d
    mo clean
