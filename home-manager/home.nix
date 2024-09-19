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
  programs = {
    neovim = import ./neovim.nix { inherit pkgs; };
    firefox = import ./firefox.nix { inherit pkgs; };
    fish = import ./fish.nix { inherit pkgs; };
    vscode = import ./vscode.nix { inherit pkgs; };
    k9s.enable = true;
    starship = {
      enable = true;
      # Configuration for Starship
      settings = pkgs.lib.importTOML ./dotfiles/starship.toml;
    };
    ssh = {
      enable = true;
      matchBlocks = {
        "github.com" = {
          identityFile = "~/.ssh/github_key";
          user = "git";
        };
      };
    };
    git = {
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
}
