#!/usr/bin/env bash
#
# rebuild.sh -- build or activate this machine's configuration.
#
# Adapted from https://github.com/ChanningHe/nix-config (scripts/rebuild.sh).
#
# `just rebuild` / `just build` / `just rebuild-trace` call this; they wrap it
# in the rebuild-pre and rebuild-post hooks, so running the script directly
# skips the secrets pull, the intent-to-add, and the sops check.
#
# -- Two lanes ---------------------------------------------------------------
#
# The lane is chosen by uname, because it is a fact about the machine you are
# standing on, not something worth a flag:
#
#   Darwin  hosts/darwin/<Host>/       -> darwinConfigurations.<Host>
#           the full nix-darwin system, activated with darwin-rebuild
#   Linux   hosts/home/<Host>/         -> homeConfigurations.<user>@<Host>
#           standalone home-manager, because the distro owns the system.
#           NixOS machines would be a third lane; there are none yet, and this
#           script deliberately does not guess -- a Linux box with hosts/home/
#           entry is treated as standalone.
#
# -- What it does that a bare rebuild line in the justfile cannot -------------
#
#   1. Bootstrap a machine that has never switched. On a Mac that means no
#      darwin-rebuild, no Xcode command line tools and no Homebrew (nix-darwin
#      manages brew, it does not install it). On Linux it means no
#      home-manager binary and, usually, no flakes enabled yet -- the closure
#      is built with --extra-experimental-features and activated from ./result.
#   2. Prefer nh. It drives the same activation through nix-output-monitor and
#      prints a package diff of what the switch actually changes. Installed by
#      home/jhl/common/core/nh.nix, so it is missing exactly once -- during
#      that first bootstrap -- and the fallback paths cover it.
#
# Usage: scripts/rebuild.sh [switch|build] [--trace] [HOSTNAME]

set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

red() { printf '\033[31m[!] %s\033[0m\n' "$1"; }
green() { printf '\033[32m[+] %s\033[0m\n' "$1"; }
yellow() { printf '\033[33m[*] %s\033[0m\n' "$1"; }

usage() {
	cat <<-EOF
		Usage: scripts/rebuild.sh [switch|build] [--trace] [HOSTNAME]

		  switch      build and activate (default)
		  build       build only, activate nothing
		  --trace     pass --show-trace, for debugging evaluation errors
		  HOSTNAME    a directory name under hosts/darwin/ on macOS, or under
		              hosts/home/ on Linux (default: this machine)
	EOF
}

ACTION="switch"
# `hostname` is not installed everywhere -- Arch does not ship inetutils by
# default, and `uname -n` is in coreutils, which every machine has.
HOST=$(uname -n)
TRACE=0

case "$(uname -s)" in
Darwin) LANE="darwin" ;;
Linux) LANE="home" ;;
*)
	red "Unsupported platform: $(uname -s)"
	exit 1
	;;
esac

while [ $# -gt 0 ]; do
	case "$1" in
	switch | build) ACTION="$1" ;;
	trace | --trace) TRACE=1 ;;
	-h | --help)
		usage
		exit 0
		;;
	-*)
		red "Unknown flag: $1"
		usage
		exit 1
		;;
	*) HOST="$1" ;;
	esac
	shift
done

# Catch a mistyped action before it is silently taken for a hostname and
# reappears as an opaque "attribute 'typo' missing" from Nix.
if [ ! -d "$repo_root/hosts/$LANE/$HOST" ]; then
	red "No such host: $HOST (expected hosts/$LANE/$HOST/)"
	known=""
	for dir in "$repo_root"/hosts/"$LANE"/*/; do
		[ -d "$dir" ] || continue
		known="$known $(basename "$dir")"
	done
	if [ -n "$known" ]; then
		yellow "Known $LANE hosts:$known"
	else
		yellow "No hosts under hosts/$LANE/ yet."
	fi
	exit 1
fi

if ! command -v nix >/dev/null 2>&1; then
	red "nix is not installed. Install it first: https://nixos.org/download"
	exit 1
fi

# ==========
# Bootstrap
# ==========

if [ "$LANE" = "darwin" ]; then
	# The Xcode command line tools ship git, which the flake needs to read its
	# own source. `xcode-select --install` is asynchronous and drives a GUI
	# dialog, so there is nothing sensible to wait on -- fire it and ask for a
	# re-run.
	if ! /usr/bin/xcode-select -p >/dev/null 2>&1; then
		yellow "Xcode command line tools are missing, opening the installer"
		xcode-select --install || true
		red "Re-run this once the installer has finished."
		exit 1
	fi

	# nix-darwin's homebrew module writes a Brewfile and runs `brew bundle`; it
	# never installs Homebrew itself, so activation fails outright without this.
	if [ ! -x /opt/homebrew/bin/brew ]; then
		if [ "$(uname -m)" = "arm64" ]; then
			# Some casks are x86_64-only, and a machine with no brew yet has
			# certainly never been asked for Rosetta.
			yellow "Installing Rosetta 2"
			softwareupdate --install-rosetta --agree-to-license
		fi
		yellow "Installing Homebrew"
		NONINTERACTIVE=1 /bin/bash -c \
			"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	fi
fi
# The home lane needs no bootstrap of its own: the distro's package manager
# already put nix, git and a shell there, and everything else this repo wants
# comes out of the generation being built.

# ==========
# Rebuild
# ==========

cd "$repo_root"

green "====== $(printf '%s' "$ACTION" | tr '[:lower:]' '[:upper:]') $HOST ======"

if [ "$LANE" = "darwin" ]; then
	if command -v nh >/dev/null 2>&1; then
		args=(darwin "$ACTION" . --hostname "$HOST")
		if [ "$TRACE" -eq 1 ]; then
			args+=(--show-trace)
		fi
		# No sudo: nh elevates itself for the activation step and refuses to run
		# as root.
		nh "${args[@]}"
	else
		args=("$ACTION" --flake ".#$HOST")
		if [ "$TRACE" -eq 1 ]; then
			args+=(--show-trace)
		fi
		# Only the activation needs root; `build` under sudo would just leave a
		# root-owned ./result behind. An empty array would be simpler, but "${a[@]}"
		# on an empty array is an unbound-variable error under `set -u` in bash 3.2,
		# and /bin/bash is what runs this while bootstrapping.
		sudo="sudo"
		if [ "$ACTION" = "build" ]; then
			sudo="command"
		fi
		if command -v darwin-rebuild >/dev/null 2>&1; then
			$sudo darwin-rebuild "${args[@]}"
		else
			# First switch on this machine. Build the closure with a plain `nix
			# build` -- flakes are enabled per invocation rather than by writing
			# ~/.config/nix/nix.conf, because that file outranks the
			# /etc/nix/nix.conf nix-darwin generates and would quietly pin
			# experimental-features to whatever was true on bootstrap day.
			yellow "darwin-rebuild not found, building the closure from the flake first"
			nix --extra-experimental-features "nix-command flakes" \
				build ".#darwinConfigurations.$HOST.system"
			$sudo ./result/sw/bin/darwin-rebuild "${args[@]}"
		fi
	fi
else
	# Standalone home-manager. No sudo anywhere on this lane -- it only ever
	# writes inside $HOME and the per-user nix profile.
	#
	# The flake attribute is "<user>@<host>", so it needs quoting all the way
	# through to nix; a bare @ in an attribute path is not the problem, the
	# surrounding attr-name quotes are.
	CONFIG="$(id -un)@$HOST"

	# Existing dotfiles are the normal case here: the distro, or you, put a
	# .zshrc there long before nix showed up. Without a backup extension
	# activation aborts on the first collision. Matches backupFileExtension on
	# the darwin lane.
	BACKUP="backup"

	if command -v nh >/dev/null 2>&1; then
		args=(home "$ACTION" . -c "$CONFIG" -b "$BACKUP")
		if [ "$TRACE" -eq 1 ]; then
			args+=(--show-trace)
		fi
		nh "${args[@]}"
	elif command -v home-manager >/dev/null 2>&1; then
		args=("$ACTION" --flake ".#$CONFIG" -b "$BACKUP")
		if [ "$TRACE" -eq 1 ]; then
			args+=(--show-trace)
		fi
		home-manager "${args[@]}"
	else
		# First switch on this machine: no nh, no home-manager, and -- since
		# home/jhl/common/optional/nix/standalone.nix is what turns flakes on --
		# quite possibly no flakes either. Build the activation package by hand
		# and run it. Unlike the darwin lane there is no objection to
		# ~/.config/nix/nix.conf here: the distro owns /etc/nix, so that file is
		# the only layer this repo can write, and it is written by the very
		# generation being built.
		yellow "home-manager not found, building the activation package from the flake first"
		buildArgs=(--extra-experimental-features "nix-command flakes"
			build ".#homeConfigurations.\"$CONFIG\".activationPackage")
		if [ "$TRACE" -eq 1 ]; then
			buildArgs+=(--show-trace)
		fi
		nix "${buildArgs[@]}"

		if [ "$ACTION" = "switch" ]; then
			# activate reads the backup extension from the environment; there is
			# no flag for it.
			HOME_MANAGER_BACKUP_EXT="$BACKUP" ./result/activate
		fi
	fi
fi

if [ "$ACTION" = "build" ]; then
	green "Build complete, nothing activated"
else
	green "Switched to new config"
fi
