{ pkgs, ... }:

{
  enable = true;
  viAlias = true;
  vimAlias = true;
  withNodeJs = true;
  withPython3 = true;
  plugins = with pkgs.vimPlugins; [ gruvbox ];
  extraConfig = ''
    set number relativenumber
    set tabstop=2 shiftwidth=2 expandtab
    syntax enable

    autocmd BufRead,BufNewFile Tiltfile set filetype=python

    set list listchars=eol:$
    colorscheme gruvbox
  '';
}
