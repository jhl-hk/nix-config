{
  lib,
  pkgs,
  ...
}:
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
#  A ~/.vimrc stops Vim from loading defaults.vim, so it is sourced first.
#  Neovim has its own defaults and needs no equivalent.
#
#  `sshv [ssh options] host` carries the same mappings to machines outside
#  this flake. It runs `ssh -t` and starts the remote login shell with
#  VIMINIT set; nothing is written on the remote. VIMINIT replaces the
#  remote's own config, so it sources that first: init.lua / init.vim for
#  nvim, ~/.vimrc (or defaults.vim) for vim. Gone under sudo, which drops
#  the environment.
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

  colemak = lib.concatLines maps;

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
    ++ maps);

  sshv = pkgs.writeShellApplication {
    name = "sshv";
    text = ''
      exec ssh -t "$@" ${lib.escapeShellArg "export VIMINIT='${viminit}'; exec \"$SHELL\" -l"}
    '';
  };
in {
  home.file.".vimrc".text = ''
    unlet! skip_defaults_vim
    source $VIMRUNTIME/defaults.vim

    ${colemak}'';

  programs.neovim = {
    enable = true;
    # y / p use the system clipboard (pbcopy on macOS, OSC 52 over ssh).
    # Soft wrap breaks at word boundaries, wrapped lines keep their indent.
    extraConfig = ''
      set clipboard=unnamedplus
      set linebreak breakindent
      ${colemak}'';
  };

  home.packages = [sshv];

  # Host completion as for ssh. After compinit (570).
  programs.zsh.initContent = lib.mkOrder 660 "compdef sshv=ssh";
}
