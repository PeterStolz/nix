{
  config,
  lib,
  pkgs,
  ...
}:

let
  username = "peter";
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
    (import ./ssh.nix {
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
      kitty = {
        enable = true;
        theme = "Birds Of Paradise";
        keybindings = {
          "ctrl+alt+enter" = "launch --cwd=current";
        };
        extraConfig = ''
          background_opacity 0.9

        '';
      };
    };
    home = {
      username = username;
      homeDirectory = "/home/${username}";
      stateVersion = "24.05";

      packages = with pkgs; [
        htop
        kubectl
        unzip
        dig
        jq
        devbox
        #(python3.withPackages (pythonPackages: [
        #  pythonPackages.torch
        # pythonPackages.torchvision
        # pythonPackages.torchaudio
        #]))
      ];

      file = {
        # Add any file configurations here
      };

      sessionVariables = {
        # Add any session variables here
      };
    };

    programs.home-manager.enable = true;
    nixpkgs.config = {
      allowUnfree = true;
      cudaSupport = true;
    };

    # This can/cloud help when nix completions don't work properly
    # xdg.configFile."fish/completions/nix.fish".source = "${pkgs.nix}/share/fish/vendor_completions.d/nix.fish";
  };
}
