{lib, ...}:
#############################################################
#
#  Starship Prompt Configuration
#
#  Laid out like Powerlevel10k -- context on the left, clock on the right,
#  a blank line between commands -- but kept as starship rather than pulling
#  in antidote + p10k, because p10k's look lives in a ~/.p10k.zsh that a
#  plugin manager sources at runtime, while everything here is a Nix attrset
#  that becomes ~/.config/starship.toml.
#
#  -- Glyphs: this config assumes NO Nerd Font ---------------------------
#
#  The only monospace font this fleet installs is the `font-maple-mono`
#  cask (hosts/common/core/darwin/apps.nix), which is Maple Mono *Variable*
#  -- not the NF build. Its cmap was checked directly, and the split is:
#
#    present  U+E0A0 (Powerline branch), U+E0A2, U+E0B0, and the plain
#             Unicode set: > (U+279C) > (U+00BB) x (U+2718) ^ v (U+2191/2193)
#    absent   every Nerd Font icon in the U+E2xx/E6xx/E7xx/Fxxx ranges
#             (node, python, rust, go, java), plus the snowflake U+2744,
#             the dharma wheel U+2638, and the double arrows U+21E1/21E3/21D5
#
#  So starship's *default* git_branch symbol is fine (it is U+E0A0), while
#  every language module's default symbol would fall back to another font
#  or render as tofu -- those are overridden with short text below. macOS
#  does substitute a fallback font rather than showing an empty box, but the
#  substitute is rarely monospaced, which shifts the whole prompt line.
#
#  Want the icon-heavy p10k look instead? Swap the cask to
#  `font-maple-mono-nf` and change `buffer_font_family` in
#  home/jhl/common/optional/editors/zed.nix to "Maple Mono NF"; the symbol
#  overrides below can then be deleted so starship's Nerd Font defaults win.
#
#############################################################
{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      add_newline = true;

      # starship prints a warning when a module takes longer than this.
      # 500ms (the default) is easy to trip on a large git worktree over a
      # network volume; the prompt still renders, it just complains.
      command_timeout = 1000;

      # Module order. Anything not listed here is not rendered at all, which
      # is the point -- it makes the prompt's contents an explicit list
      # rather than "whatever starship enables by default".
      format = lib.concatStrings [
        "$username"
        "$hostname"
        "$directory"
        "$git_branch"
        "$git_state"
        "$git_status"
        "$nix_shell"
        "$nodejs"
        "$python"
        "$rust"
        "$golang"
        "$java"
        "$kubernetes"
        "$cmd_duration"
        "$line_break"
        "$character"
      ];

      right_format = "$time";

      character = {
        success_symbol = "[➜](bold green)";
        error_symbol = "[➜](bold red)";
      };

      # username/hostname stay quiet locally: starship only renders username
      # for root or over SSH, and hostname is ssh_only by default. Both are
      # listed in `format` purely so an SSH session is visibly different.
      hostname = {
        ssh_only = true;
        format = "[$hostname]($style) ";
        style = "bold red";
      };

      directory = {
        truncation_length = 3;
        truncate_to_repo = true;
        style = "bold cyan";
        # Default is a padlock emoji, which is absent from Maple Mono and
        # would be drawn by the colour-emoji fallback at double width.
        read_only = " RO";
        read_only_style = "bold red";
      };

      # symbol is left at starship's default U+E0A0 -- the one Powerline
      # glyph Maple Mono does ship.
      git_branch.style = "bold purple";

      # Rebase / merge / cherry-pick in progress, with the step counter.
      git_state.style = "bold yellow";

      git_status = {
        style = "bold yellow";
        # Counts rather than bare markers, the way p10k shows them. The
        # defaults for ahead/behind/diverged are U+21E1/21E3/21D5, none of
        # which Maple Mono has; the single arrows below do exist.
        ahead = "↑\${count}";
        behind = "↓\${count}";
        diverged = "↕↑\${ahead_count}↓\${behind_count}";
        conflicted = "=\${count}";
        untracked = "?\${count}";
        stashed = "*\${count}";
        modified = "!\${count}";
        staged = "+\${count}";
        renamed = "»\${count}";
        deleted = "✘\${count}";
      };

      # How long the last command took. Silent under 2s so ordinary commands
      # do not add a segment.
      cmd_duration = {
        min_time = 2000;
        format = "took [$duration]($style) ";
        style = "bold yellow";
      };

      time = {
        disabled = false;
        format = "[$time]($style)";
        time_format = "%H:%M:%S";
        style = "bright-black";
      };

      # Text symbols from here down: every one of these modules defaults to a
      # Nerd Font icon. They stay gated by starship's own detection (a
      # package.json, a Cargo.toml, ...), so they only appear in a project
      # that actually uses the language.
      nix_shell = {
        symbol = "nix ";
        format = "via [$symbol$state( \\($name\\))]($style) ";
        style = "bold blue";
      };

      nodejs.symbol = "node ";
      python.symbol = "py ";
      rust.symbol = "rs ";
      golang.symbol = "go ";
      java.symbol = "java ";

      # Off by default in starship, and left *conditional* here rather than
      # always-on: with no detection rules it renders on every prompt as soon
      # as kubectl has a current-context, which on this fleet is always.
      kubernetes = {
        disabled = false;
        symbol = "k8s ";
        format = "on [$symbol$context( \\($namespace\\))]($style) ";
        style = "bold cyan";
        detect_files = ["k8s.yaml" "kustomization.yaml" "Chart.yaml" "skaffold.yaml"];
        detect_folders = ["k8s" "kubernetes" "helm" "manifests"];
      };
    };
  };
}
