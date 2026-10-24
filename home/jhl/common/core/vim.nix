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
#############################################################
let
  colemak = ''
    for s:m in ['n', 'x', 'o']
      for [s:from, s:to] in [
            \ ['n', 'j'], ['e', 'k'], ['i', 'l'],
            \ ['j', 'e'], ['k', 'n'], ['l', 'i'],
            \ ['N', 'J'], ['E', 'K'], ['I', 'L'],
            \ ['J', 'E'], ['K', 'N'], ['L', 'I']]
        execute s:m . 'noremap ' . s:from . ' ' . s:to
      endfor
    endfor
  '';
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
}
