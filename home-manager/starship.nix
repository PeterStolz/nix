{
  config,
  lib,
  pkgs,
  username,
  ...
}:

{
  home-manager.users.${username} = {
    programs.starship = {
      enable = true;
      # Configuration for Starship
      settings = pkgs.lib.importTOML ./dotfiles/starship.toml;
    };
  };
}
