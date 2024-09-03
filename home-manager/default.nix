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
    (import ./vscode.nix {
      inherit
        config
        lib
        pkgs
        username
        ;
    })
    (import ./starship.nix {
      inherit
        config
        lib
        pkgs
        username
        ;
    })
    (import ./git.nix {
      inherit
        config
        lib
        pkgs
        username
        ;
    })
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
    programs = {
      k9s.enable = true;
      kitty.enable = true;
    };
    home = {
      username = username;
      homeDirectory = "/home/${username}";
      stateVersion = "24.05";

      packages = [
        pkgs.htop
        pkgs.kubectl
        pkgs.unzip
        pkgs.dig
        pkgs.jq
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
