{
  config,
  lib,
  pkgs,
  ...
}:

let
  username = "peter"; # Define the username here
in
{
  imports = [
    (import ./firefox.nix {
      inherit
        config
        lib
        pkgs
        username
        ;
    })
    (import ./fish.nix {
      inherit
        config
        lib
        pkgs
        username
        ;
    })
    (import ./neovim.nix {
      inherit
        config
        lib
        pkgs
        username
        ;
    })
  ];

  home-manager.users.${username} = {
    home = {
      username = username;
      homeDirectory = "/home/${username}";
      stateVersion = "24.05";

      packages = [
        # Add any additional packages here
      ];

      file = {
        # Add any file configurations here
      };

      sessionVariables = {
        # Add any session variables here
      };
    };

    programs.home-manager.enable = true;
  };
}
