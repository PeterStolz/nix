{
  config,
  lib,
  pkgs,
  ...
}:

let
  username = builtins.getEnv "USER";

  commonPackages = with pkgs; [
    thunderbird-128
    keepassxc
    nixfmt-rfc-style
    htop
    kubectl
    unzip
    redis
    mlocate
    dig
    libargon2
    pinentry-all
    hcloud
    ffmpeg_7
    jq
    devbox
    file
    gnupg
    opentofu
    tor-browser
    ansible
    k3d
    linkerd
    gh
    kubernetes-helm
    s3cmd
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
    nix-index
    (python312.withPackages (p: [ p.conda ]))
  ];

  # Packages only available or relevant on Linux
  linuxOnlyPackages = with pkgs; [
    # Add packages that won't work on Darwin here
    # e.g. chromium if it doesn't support Darwin
  ];

in
{
  # Enable Home Manager programs
  programs = {
    neovim = import ./neovim.nix { inherit pkgs; };
    fish = import ./fish.nix { inherit pkgs; };
    vscode = import ./vscode.nix { inherit pkgs; };
    firefox = import ./firefox.nix { inherit pkgs; };

    k9s.enable = true;
    starship = {
      enable = true;
      settings = pkgs.lib.importTOML ./dotfiles/starship.toml;
    };

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
        gpg.program = "gpg";
        push.autoSetupRemote = true;
        commit.gpgsign = true;
        core.editor = "nvim";
        core.autocrlf = "input";
        init.defaultBranch = "main";
        safe.directory = "/etc/nixos";
        stash.showPatch = true;
        pull.rebase = true;
      };
    };

    yt-dlp.enable = true;

    # Only enable Chromium if not on Darwin
    chromium = lib.mkIf (!pkgs.stdenv.isDarwin) {
      enable = true;
      extensions = [
        { id = "fmkadmapgofadopljbjfkapdkoienihi"; } # React DevTools
        { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; } # uBlock Origin
      ];
      dictionaries = [ pkgs.hunspellDictsChromium.en_US ];
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

    # Home directory differs between Darwin and Linux
    homeDirectory = if pkgs.stdenv.isDarwin then "/Users/${username}" else "/home/${username}";
    stateVersion = "24.05";

    # Packages common to both Darwin and Linux
    packages = commonPackages ++ lib.optionals (!pkgs.stdenv.isDarwin) linuxOnlyPackages;

    file = {
      # Additional file configurations can go here
    };

    sessionVariables = {
      # Additional session variables can go here
    };
  };

  programs.home-manager.enable = true;

  nixpkgs.config = {
    allowUnfree = true;
    cudaSupport = true;
  };
}
