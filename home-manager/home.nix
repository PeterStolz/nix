{
  config,
  lib,
  pkgs,
  ...
}:

let
  username = builtins.getEnv "USER";

  commonPackages = with pkgs; [
    ansible
    actionlint
    # argocd
    btop
    # checkov # does not build atm due to cuda_cudart-12.8.90 but works in nix-shell
    cargo
    cmake
    cmctl
    ctlptl
    devbox
    dig
    duckdb
    exiftool
    ffmpeg_7
    file
    gh
    ghostscript
    gitleaks
    gnumake
    gnupg
    go
    go-task
    google-cloud-sdk
    graphviz
    hadolint
    hcloud
    htop
    hyperfine
    imagemagick
    iperf
    jq
    k3d
    keepassxc
    kind
    kubectl
    kubernetes-helm
    kustomize
    lakectl
    libargon2
    libwebp
    linkerd
    micromamba # alledgedly the same as mamba now https://github.com/NixOS/nixpkgs/pull/460788 but broken for now
    mongosh
    nil
    nix-index
    nixfmt
    nodejs_24
    nmap
    yarn-berry_4
    opentelemetry-collector-contrib
    opentofu
    tofu-ls
    pinentry-tty
    poppler-utils
    postgresql_16
    pre-commit
    pnpm
    (python312.withPackages (python-pkgs: [
      # python-pkgs.dvc
      # python-pkgs.dvc-s3
      # python-pkgs.black
      # python-pkgs.mypy
      # python-pkgs.flake8
      # python-pkgs.ruff
      # python-pkgs.semgrep
      # python-pkgs.typer
    ]))
    pqrs
    rclone
    redis
    ripgrep
    ripgrep-all
    s3cmd
    # s3fs
    sshfs
    talosctl
    teleport
    terraform
    terraform-ls
    tflint
    tilt
    time
    tree
    # trivy
    unzip
    uv
    watch
    wget
    yq-go
  ];

  # Packages only available or relevant on Linux
  linuxOnlyPackages = with pkgs; [
    # Add packages that won't work on Darwin here
    # e.g. chromium if it doesn't support Darwin
    mlocate
    #thunderbird-128
    tor-browser
    fio
    #conda
    #(python312.withPackages (p: [ p.conda ]))
  ];
  darwinOnlyPackages = with pkgs; [
    cyberduck
  ];

in
{

  # Enable Home Manager programs
  programs = {
    delta = {
      enable = true;
      enableGitIntegration = true;
      options = {
        line-numbers = true;
        side-by-side = true;
      };
    };
    zsh = {
      enable = true;
      initContent = ''
        export PATH="$HOME/.nix-profile/bin/:$PATH"

        if [[ -o interactive ]]; then
          if [ -z "$INTELLIJ_ENVIRONMENT_READER" ]; then
            exec fish
          fi
        fi
      '';
    };
    bash = {
      enable = true;

      # This is appended to ~/.bashrc (interactive shells)
      initExtra = ''
        export PATH="$HOME/.nix-profile/bin/:$PATH"

        # Only for interactive shells
        case $- in
          *i*)
            exec fish
            ;;
        esac
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

    git = import ./git.nix { inherit pkgs; };
    yt-dlp.enable = true;

    kitty = {
      enable = true;
      themeFile = "BirdsOfParadise";
      keybindings = {
        "ctrl+alt+enter" = "launch --cwd=current";
      };
      extraConfig = ''
        scrollback_lines 100000
        background_opacity 0.9
        cursor                #ffffff
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

    # https://github.com/nix-community/home-manager/issues/1341
    activation.link-apps = lib.hm.dag.entryAfter [ "linkGeneration" ] (
      if pkgs.stdenv.isDarwin then
        ''
          new_nix_apps="${config.home.homeDirectory}/Applications/Nix"
          rm -rf "$new_nix_apps"
          mkdir -p "$new_nix_apps"
          find -H -L "$newGenPath/home-files/Applications" -name "*.app" -type d -print | while read -r app; do
            real_app=$(readlink -f "$app")
            app_name=$(basename "$app")
            target_app="$new_nix_apps/$app_name"
            echo "Alias '$real_app' to '$target_app'"
            ${pkgs.mkalias}/bin/mkalias "$real_app" "$target_app"
          done
        ''
      else
        ""
    );

    enableNixpkgsReleaseCheck = false;
    username = username;

    # Home directory differs between Darwin and Linux
    homeDirectory = if pkgs.stdenv.isDarwin then "/Users/${username}" else "/home/${username}";
    stateVersion = "24.05";

    # Packages common to both Darwin and Linux
    packages =
      commonPackages
      ++ lib.optionals (!pkgs.stdenv.isDarwin) linuxOnlyPackages
      ++ lib.optionals (pkgs.stdenv.isDarwin) darwinOnlyPackages;

    file = {
      # Additional file configurations can go here
      ".hushlogin".text = "";
      ".condarc".text = ''
        channels:
        - conda-forge
        changeps1: False
        always_yes: True
      '';
      ".npmrc".text = ''
        prefix=${config.home.homeDirectory}/.local/lib

        # Supply-chain hardening (pnpm 10+): refuse anything published <7 days ago.
        # https://pnpm.io/settings#minimum-release-age
        minimum-release-age=10080
        strict-peer-dependencies=true
      '';
      ".config/uv/uv.toml".text = ''
        # Supply-chain hardening: ignore packages published in the last 7 days.
        # https://docs.astral.sh/uv/reference/settings/#exclude-newer
        exclude-newer = "7 days"
      '';
    };

    sessionVariables = {
      PATH = "$HOME/.nix-profile/bin:$PATH";
    };
  };

  nixpkgs.config = {
    allowUnfree = true;
    cudaSupport = false;
  };
}
