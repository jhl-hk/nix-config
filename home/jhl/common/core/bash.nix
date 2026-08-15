{...}:
#############################################################
#
#  Bash
#
#  The sibling of ./zsh.nix, and on jhlsArchLinux it is the shell that actually
#  runs: Arch creates users with /bin/bash and nothing in this repo can call
#  chsh, so until that is changed by hand, every login there lands here.
#
#  Before this file existed that login got **none** of home-manager: no
#  hm-session-vars.sh, so no EDITOR, no NH_FLAKE, no STARSHIP_CONFIG, no
#  SOPS_AGE_KEY_FILE; no aliases; no prompt. The whole home configuration was
#  one `chsh` away from being invisible, which is a bad way to hold a laptop.
#
#  On the Macs zsh is the login shell, so this is a fallback: the shell you get
#  from a stray `bash -l`, a script with a bash shebang, or a recovery session.
#  It is in core rather than the Linux half so those cases behave the same way
#  everywhere -- same aliases, same prompt, same variables.
#
#  -- What is shared with zsh, and where it lives -------------------------
#
#  Nothing about aliases or session variables is repeated here. home-manager
#  copies home.shellAliases into both shells' own shellAliases option, and
#  hm-session-vars.sh is sourced by both, so ./default.nix declares each once:
#
#    sysnew / sysup / syscl   home.shellAliases
#    SOPS_AGE_KEY_FILE        home.sessionVariables
#
#  starship and zoxide hook themselves in the same way. Their enableBash-
#  Integration options default to programs.bash.enable, so both light up the
#  moment this file lands; ./starship.nix and ./zoxide.nix set them explicitly
#  all the same, the way they already do for zsh.
#
#  -- What is deliberately *not* shared -----------------------------------
#
#  ./darwin.nix's Homebrew / JAVA_HOME / per-user-profile PATH block stays
#  zsh-only. It **prepends**, and its position between the nix paths and
#  /usr/bin is load-bearing (the reasoning is in that file and in
#  hosts/common/core/darwin.nix). home.sessionPath -- the option both shells
#  would share -- appends instead, so moving it there to cover bash would
#  quietly invert the order that block exists to get right. bash on a Mac
#  therefore gets /opt/homebrew/bin, which comes from home.sessionPath, but not
#  sbin or openjdk. That is a known gap on a shell nobody logs into there, not
#  an oversight.
#
#############################################################
{
  programs.bash = {
    enable = true;
    enableCompletion = true;

    # zsh keeps 10000 in memory (./zsh.nix) and this matches it. The file is
    # allowed to be much larger: the point of erasedups below is that the file
    # is where the deduplicated history accumulates over months, while the
    # in-memory list only has to cover the current session.
    historySize = 10000;
    historyFileSize = 100000;

    # ignoredups drops a command that repeats the one before it; erasedups goes
    # further and removes every earlier copy anywhere in the list. Together
    # they are what make a long historyFileSize useful rather than a wall of
    # `ls`, `git status`, `ls`.
    historyControl = ["ignoredups" "erasedups"];

    # Noise with no recall value -- you never reach for these in Ctrl-R, and
    # leaving them in pushes real commands out of view.
    historyIgnore = ["ls" "ll" "cd" "cd -" "pwd" "exit" "clear" "history"];

    # This option **replaces** home-manager's default list, it does not extend
    # it, so the four defaults are restated -- leaving one out here silently
    # turns it off.
    shellOptions = [
      # home-manager's defaults (modules/programs/bash.nix).
      "histappend" # append on exit instead of overwriting; erasedups below needs it to persist
      "extglob" # ?() *() +() @() !() patterns
      "globstar" # ** recurses into subdirectories
      "checkjobs" # refuse the first exit attempt while jobs are running

      # Added on top.
      "checkwinsize" # re-read the terminal size after every command, so a resize does not wrap wrongly
      "cmdhist" # store a multi-line command as one history entry rather than one line each
    ];
  };
}
