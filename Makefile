.PHONY: switch update clean build info help

# Default host (change this to your hostname)
HOSTNAME := jhlsMacBookAir

help: ## Show this help message
	@echo "Nix Configuration Makefile"
	@echo ""
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

switch: ## Build and switch to new configuration
	darwin-rebuild switch --flake .#$(HOSTNAME)

build: ## Build configuration without switching
	darwin-rebuild build --flake .#$(HOSTNAME)

check: ## Check flake for errors
	nix flake check

update: ## Update flake inputs
	nix flake update

clean: ## Remove old generations (older than 7 days)
	sudo nix-collect-garbage --delete-older-than 7d
	nix-collect-garbage --delete-older-than 7d

clean-all: ## Remove all old generations
	sudo nix-collect-garbage -d
	nix-collect-garbage -d

info: ## Show system information
	@echo "Current System Info:"
	@echo "===================="
	@darwin-rebuild --version 2>/dev/null || echo "nix-darwin not installed"
	@echo ""
	@nix --version
	@echo ""
	@echo "Current hostname: $(HOSTNAME)"
	@echo "Flake location: $$(pwd)"

fmt: ## Format nix files
	nix fmt

show: ## Show flake outputs
	nix flake show

history: ## Show system generations
	nix profile history --profile /nix/var/nix/profiles/system

diff: ## Show what would change
	darwin-rebuild build --flake .#$(HOSTNAME) && nix store diff-closures /run/current-system ./result
