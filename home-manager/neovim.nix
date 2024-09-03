{ config, lib, pkgs, username, ... }:

{
  home-manager.users.${username} = {
    programs.neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
      extraConfig = ''
        set number relativenumber
      '';
    };
  };
}
