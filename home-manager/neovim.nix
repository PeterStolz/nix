{
  config,
  lib,
  pkgs,
  username,
  ...
}:

{
  home-manager.users.${username} = {
    programs.neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
      extraConfig = ''
              set number relativenumber
              set tabstop=2 shiftwidth=2 expandtab
        syntax enable

        autocmd BufRead,BufNewFile Tiltfile set filetype=python

        set list listchars=eol:$
        colorscheme gruvbox
      '';
    };
  };
}
