{lib, ...}:
#############################################################
#
#  Vim -- ~/.vimrc only; Neovim -- binary and init.lua
#
#  The Vim binary comes from the system side (hosts/common/core) or the
#  distro. Neovim comes from home-manager. EDITOR stays vim.
#
#  Colemak navigation, shared by both: h/n/e/i are left/down/up/right.
#  Displaced keys:
#    n -> j   down             j -> e   end of word
#    e -> k   up               k -> n   next match
#    i -> l   right            l -> i   insert
#  Uppercase follows: N join, E keyword lookup, I bottom of screen,
#  J end of WORD, K previous match, L insert at BOL.
#  Text objects move with insert: `dlw` is the old `diw`.
#
#  Indent: 2 spaces. Filetype plugins that set their own (Python's 4) win.
#
#  A ~/.vimrc stops Vim from loading defaults.vim, so it is sourced first.
#  Neovim has its own defaults and needs no equivalent.
#
#  An interactive `ssh host` (bash and zsh function below) carries the same
#  mappings and indent to any remote. It runs `ssh -t` and starts the remote
#  login shell with VIMINIT set. VIMINIT replaces the remote's own config,
#  so it sources that first: init.lua / init.vim for nvim, ~/.vimrc (or
#  defaults.vim) for vim. Gone under sudo, which drops the environment.
#
#  Anything else goes to the ssh binary unchanged: a remote command, -f -G
#  -N -O -Q -s -T -V -W, stdin/stdout not a terminal, or a host whose
#  resolved config sets `Tag noshell` (network gear with a vendor CLI, no
#  POSIX shell). Scripts, git, rsync and scp never see the function.
#
#  Under TERM=xterm-ghostty the function first installs the terminfo entry
#  into the remote's ~/.terminfo, once per user@host:port (cached in
#  ~/.cache/ssh-terminfo). Where that fails the remote falls back to
#  TERM=xterm-256color. This replaces Ghostty's own ssh integration, which
#  would shadow the function (./darwin/ghostty.nix).
#
#  `_ssh_prepare`, when defined, runs first (./darwin/ssh-agent.nix).
#
#############################################################
let
  # [from to], applied in normal, visual and operator-pending mode.
  pairs = [
    ["n" "j"]
    ["e" "k"]
    ["i" "l"]
    ["j" "e"]
    ["k" "n"]
    ["l" "i"]
    ["N" "J"]
    ["E" "K"]
    ["I" "L"]
    ["J" "E"]
    ["K" "N"]
    ["L" "I"]
  ];

  maps = lib.concatMap (mode: map (p: "${mode}noremap ${lib.elemAt p 0} ${lib.elemAt p 1}") pairs) ["n" "x" "o"];

  shared = ["set expandtab tabstop=2 shiftwidth=2 softtabstop=2"] ++ maps;

  sharedLines = lib.concatLines shared;

  # One Ex line. No spaces before `|`: they would become part of the rhs.
  # Double quotes only, so the remote shell can single-quote it.
  viminit = lib.concatStringsSep "|" ([
      ''if has("nvim")''
      ''if filereadable(stdpath("config") . "/init.lua")''
      ''exe "luafile" fnameescape(stdpath("config") . "/init.lua")''
      ''elseif filereadable(stdpath("config") . "/init.vim")''
      ''exe "source" fnameescape(stdpath("config") . "/init.vim")''
      ''endif''
      ''elseif filereadable(expand("~/.vimrc"))''
      ''source ~/.vimrc''
      ''else''
      ''source $VIMRUNTIME/defaults.vim''
      ''endif''
    ]
    ++ shared);

  # Runs in the remote login shell: POSIX sh, bash, zsh or fish.
  remote = lib.concatStringsSep "; " [
    ''test "$TERM" = xterm-ghostty && ! infocmp xterm-ghostty >/dev/null 2>&1 && export TERM=xterm-256color''
    "export VIMINIT='${viminit}'"
    ''exec "$SHELL" -l''
  ];

  # Remote side runs as POSIX sh / fish. -o keeps root's entry out of the
  # system terminfo database.
  installTerminfo = "infocmp xterm-ghostty >/dev/null 2>&1 && exit 0; command -v tic >/dev/null 2>&1 || exit 1; mkdir -p ~/.terminfo && tic -x -o ~/.terminfo - 2>/dev/null";

  # Valid in both bash and zsh.
  sshFunction = ''
    # Succeeds when the arguments are an interactive login: one destination,
    # no command, no flag from the pass-through list. OpenSSH accepts options
    # after the destination, hence the outer loop.
    __ssh_is_login() {
      local opt n=0 OPTIND
      while [ $# -gt 0 ]; do
        OPTIND=1
        while getopts 46AaCfGgKkMNnqsTtVvXxYyB:b:c:D:E:e:F:I:i:J:L:l:m:O:o:P:p:Q:R:S:W:w: opt; do
          case $opt in
            f | G | N | O | Q | s | T | V | W | '?') return 1 ;;
          esac
        done
        shift $((OPTIND - 1))
        [ $# -gt 0 ] || break
        n=$((n + 1))
        shift
      done
      [ "$n" -eq 1 ]
    }

    __ssh_terminfo() {
      local cache="''${XDG_CACHE_HOME:-$HOME/.cache}/ssh-terminfo" key info
      key=$(command ssh -G "$@" 2>/dev/null | awk '$1 == "user" { u = $2 } $1 == "hostname" { h = $2 } $1 == "port" { p = $2 } END { print u "@" h ":" p }')
      grep -qxF "$key" "$cache" 2>/dev/null && return
      info=$(infocmp -0 -x xterm-ghostty 2>/dev/null) || return
      if printf '%s\n' "$info" | command ssh -T "$@" ${lib.escapeShellArg installTerminfo}; then
        mkdir -p "''${cache%/*}" && printf '%s\n' "$key" >>"$cache"
      fi
    }

    ssh() {
      command -v _ssh_prepare >/dev/null 2>&1 && _ssh_prepare
      if [ ! -t 0 ] || [ ! -t 1 ] || ! __ssh_is_login "$@" ||
        command ssh -G "$@" 2>/dev/null | grep -qx 'tag noshell'; then
        command ssh "$@"
        return
      fi
      [ "$TERM" = xterm-ghostty ] && __ssh_terminfo "$@"
      command ssh -t "$@" ${lib.escapeShellArg remote}
    }
  '';
in {
  home.file.".vimrc".text = ''
    unlet! skip_defaults_vim
    source $VIMRUNTIME/defaults.vim

    ${sharedLines}'';

  programs.neovim = {
    enable = true;
    # y / p use the system clipboard (pbcopy on macOS, OSC 52 over ssh).
    # Soft wrap breaks at word boundaries, wrapped lines keep their indent.
    extraConfig = ''
      set clipboard=unnamedplus
      set linebreak breakindent
      ${sharedLines}'';
  };

  programs.bash.initExtra = sshFunction;
  programs.zsh.initContent = sshFunction;
}
