{
  config,
  lib,
  pkgs,
  username,
  ...
}:

{
  home-manager.users.${username} = {
    programs.git = {
      enable = true;
      userName = "Your Name";
      userEmail = "your.email@example.com";
      extraConfig = {
        core.editor = "nvim";
        init.defaultBranch = "main";
      };
    };
  };
}
