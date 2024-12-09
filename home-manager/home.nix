{
  config,
  lib,
  pkgs,
  ...
}:

let
  username = builtins.getEnv "USER";

  commonPackages = with pkgs; [
    keepassxc
    nixfmt-rfc-style
    htop
    kubectl
    unzip
    redis
    dig
    libargon2
    hcloud
    ffmpeg_7
    jq
    devbox
    file
    gnupg
    opentofu
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
    imagemagick
    hadolint
    pre-commit
    nodejs_20
    yarn
    nix-index
  ];

  # Packages only available or relevant on Linux
  linuxOnlyPackages = with pkgs; [
    # Add packages that won't work on Darwin here
    # e.g. chromium if it doesn't support Darwin
    mlocate
    thunderbird-128
    pinentry-all
    tor-browser
    conda
    (python312.withPackages (p: [ p.conda ]))
  ];

in
{

  # Enable Home Manager programs
  programs =
    {
      zsh = {
        enable = true;
        initExtra = ''
          if [[ -o interactive ]]; then
            exec fish
          fi
        '';
      };
      home-manager.enable = true;
      neovim = import ./neovim.nix { inherit pkgs; };
      fish = import ./fish.nix { inherit pkgs; };
      vscode = import ./vscode.nix { inherit pkgs; };

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

      kitty = {
        enable = true;
        themeFile = "BirdsOfParadise";
        keybindings = {
          "ctrl+alt+enter" = "launch --cwd=current";
        };
        extraConfig = ''
          background_opacity 0.9
        '';
      };
    }
    // (
      if !pkgs.stdenv.isDarwin then
        {
          chromium = {
            enable = true;
            extensions = [
              { id = "fmkadmapgofadopljbjfkapdkoienihi"; } # React DevTools
              { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; } # uBlock Origin
            ];
            dictionaries = [ pkgs.hunspellDictsChromium.en_US ];
          };

          firefox = import ./firefox.nix { inherit pkgs; };

        }
      else
        { }
    );

  home = {
    enableNixpkgsReleaseCheck = false;
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

  nixpkgs.config = {
    allowUnfree = true;
    cudaSupport = true;
  };
}
