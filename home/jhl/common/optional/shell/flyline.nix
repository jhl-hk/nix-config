{...}:
#############################################################
#
#  Flyline -- the Bash half
#
#  Pairs with hosts/common/optional/darwin/flyline.nix, which is what
#  actually installs the library. Import both or neither.
#
#  Flyline is a Bash loadable builtin, so it has no effect in zsh -- and zsh
#  is the login shell here (home/jhl/common/core/zsh.nix). This file exists
#  so that dropping into `bash` gets the flyline editor; it deliberately
#  does not touch the login shell.
#
#  programs.bash.enable does two things worth knowing:
#    - installs pkgs.bashInteractive (5.3) into the home profile, which is
#      what `bash` resolves to since zsh.nix puts
#      /etc/profiles/per-user/$USER/bin ahead of /opt/homebrew/bin. That
#      matters: upstream's README says macOS's /bin/bash 3.2 cannot load
#      custom builtins. (It can, in current macOS -- but 3.2 is from 2007
#      and flyline is only regression-tested against it, so aim the editor
#      at the modern one.)
#    - writes ~/.bashrc, ~/.bash_profile and ~/.profile. None of those
#      existed before, so nothing is being taken over; if you ever hand-write
#      one, home-manager will refuse to activate rather than clobber it.
#
#  initExtra lands *after* home-manager's own `[[ $- == *i* ]] || return`,
#  which is the guard flyline asks for -- loading it in a non-interactive
#  shell makes `enable` fail with "load function for flyline returns
#  failure (0): not loaded". The readability test below covers the other
#  case: the brew not being installed yet on a fresh machine, where a bare
#  `enable -f` would print an error on every prompt.
#
#############################################################
{
  programs.bash = {
    enable = true;

    initExtra = ''
      # Flyline: readline replacement, loaded as a Bash builtin.
      # Path comes from the homebrew formula -- see the header of
      # hosts/common/optional/darwin/flyline.nix.
      if [[ -r /opt/homebrew/lib/bash/flyline ]]; then
        enable -f /opt/homebrew/lib/bash/flyline flyline
      fi
    '';
  };
}
