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
      lfs.enable = true;
      extraConfig = {
        core.editor = "nvim";
        init.defaultBranch = "main";
        safe.directory = "/etc/nixos";
      };
    };
  };
}
