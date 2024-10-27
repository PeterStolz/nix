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
    # firefox = import ./firefox.nix { inherit pkgs; };
    fish = import ./fish.nix { inherit pkgs; };
    vscode = import ./vscode.nix { inherit pkgs; };
    k9s.enable = true;
    starship = {
      enable = true;
      # Configuration for Starship
      settings = pkgs.lib.importTOML ./dotfiles/starship.toml;
    };
    #ssh = {
    #  enable = true;
    #  matchBlocks = {
    #    "github.com" = {
    #      identityFile = "~/.ssh/github_key";
    #      user = "git";
    #    };
    #  };
    #};
    git = {
      enable = true;
      userName = "Peter Stolz";
      userEmail = "50801264+PeterStolz@users.noreply.github.com";
      lfs.enable = true;
      aliases = {
        graph = "log --all --decorate --oneline --graph";
      };
      extraConfig = {
        user.signingkey = "1D68343249781AD9";
        commit.gpgsign = true;
        core.editor = "nvim";
        core.autocrlf = "input";
        init.defaultBranch = "main";
        safe.directory = "/etc/nixos";
        stash.showPatch = true;
      };
    };
    yt-dlp.enable = true;
    #kitty = {
    #  enable = true;
    #  theme = "Birds Of Paradise";
    #  keybindings = {
    #    "ctrl+alt+enter" = "launch --cwd=current";
    #  };
    #  extraConfig = ''
    #    background_opacity 0.9
    #  '';
    #};
  };
  home = {
    username = username;
    homeDirectory = "/home/${username}";
    stateVersion = "24.05";

    packages = with pkgs; [
      nixfmt-rfc-style
      htop
      kubectl
      unzip
      dig
      jq
      devbox
      file
      opentofu
      tor-browser
      ansible
      k3d
      linkerd
      gh
      kubernetes-helm
      tilt
      postgresql_16
      argocd
      cmctl
      micromamba
      conda
      imagemagick
      hadolint
      pre-commit
      nodejs_20
      yarn
      (python312.withPackages (p: [
        p.conda
      ]))
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
