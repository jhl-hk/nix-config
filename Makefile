.PHONY: switch update clean build info help

# Auto-detect hostname, or use override if provided
HOSTNAME ?= $(shell hostname | cut -d. -f1)

help: ## Show this help message
	@echo "Nix Configuration Makefile"
	@echo ""
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

switch: ## Build and switch to new configuration
	sudo darwin-rebuild switch --flake .#$(HOSTNAME)

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

sha: ## Get SHA256 hash for GitHub repo (usage: make sha owner/repo)
	@if [ -z "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		echo "Error: Repository path is required"; \
		echo "Usage: make sha <owner/repo> [BRANCH=branch_name]"; \
		echo ""; \
		echo "Examples:"; \
		echo "  make sha jhl-hk/typora-themes"; \
		echo "  make sha owner/repo BRANCH=main"; \
		echo "  make sha owner/repo BRANCH=develop"; \
		exit 1; \
	fi
	@REPO_PATH="$(filter-out $@,$(MAKECMDGOALS))"; \
	BRANCH=$${BRANCH:-main}; \
	REPO_URL="https://github.com/$$REPO_PATH"; \
	ARCHIVE_URL="$${REPO_URL}/archive/refs/heads/$${BRANCH}.tar.gz"; \
	echo "Fetching hash for: $$REPO_URL (branch: $$BRANCH)"; \
	echo ""; \
	OLD_HASH=$$(nix-prefetch-url --unpack "$$ARCHIVE_URL" 2>/dev/null | tail -1); \
	if [ -z "$$OLD_HASH" ]; then \
		echo "Error: Failed to fetch repository"; \
		exit 1; \
	fi; \
	SRI_HASH=$$(nix hash to-sri sha256:$$OLD_HASH 2>&1 | grep "sha256-"); \
	echo "Repository: $$REPO_URL"; \
	echo "Branch:     $$BRANCH"; \
	echo ""; \
	echo "Use in your .nix file:"; \
	echo "  sha256 = \"$$SRI_HASH\";"

# Prevent make from treating repo path as a target
%:
	@:
