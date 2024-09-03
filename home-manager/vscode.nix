{
  config,
  lib,
  pkgs,
  username,
  ...
}:

{
  home-manager.users.${username} = {
    programs.vscode = {
      enable = true;
    };
  };
}
