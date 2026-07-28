{
  config,
  lib,
  pkgs,
  ...
}:

let
  username = builtins.getEnv "USER";

  commonPackages = with pkgs; [
    actionlint
    ansible
    # argocd
    bitwarden-cli
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
    nmap
    nodejs_24
    opentelemetry-collector-contrib
    opentofu
    pinentry-tty
    pnpm
    poppler-utils
    postgresql_16
    pqrs
    pre-commit
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
    rclone
    redis
    ripgrep
    ripgrep-all
    s3cmd
    # s3fs
    shellcheck
    sshfs
    step-cli
    talosctl
    teleport
    # terraform / terraform-ls dropped: opentofu + tofu-ls cover the same ground
    # and terraform is BUSL-licensed.
    tflint
    tilt
    time
    tofu-ls
    tree
    # trivy
    unzip
    uv
    watch
    wget
    yarn-berry_4
    yq-go
  ];

  # Packages only available or relevant on Linux
  linuxOnlyPackages = with pkgs; [
    # Add packages that won't work on Darwin here
    # e.g. chromium if it doesn't support Darwin
    mlocate
    #thunderbird-128
    fio
    #conda
    #(python312.withPackages (p: [ p.conda ]))
  ];
  # Linux packages that need a display — skipped when headless.
  linuxGuiPackages = with pkgs; [
    tor-browser
  ];

  darwinOnlyPackages = with pkgs; [
    cyberduck
  ];

  # Absolute path so the trampolines below do not depend on PATH already being
  # set up. fish sources hm-session-vars.fish itself, so it bootstraps its own
  # environment from there.
  fishExe = "${pkgs.fish}/bin/fish";

in
{
  imports = [
    ./firefox.nix
    ./fish.nix
    ./git.nix
    ./neovim.nix
    ./vscode.nix
  ];

  options.local.headless = lib.mkOption {
    type = lib.types.bool;
    default = builtins.getEnv "HM_HEADLESS" == "1";
    description = ''
      Set HM_HEADLESS=1 for boxes with no display (agent VMs, servers) to skip the
      GUI apps — browsers, vscode, kitty. They can never run there and only cost
      download time and disk.
    '';
  };

  config = {
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
        # Run this BEFORE home-manager's compinit/starship/kitty init (mkBefore =>
        # order 500, ahead of compinit at 550). For interactive sessions we exec
        # straight into fish, so none of that zsh setup work is wasted.
        initContent = lib.mkBefore ''
          if [[ -o interactive ]]; then
            if [ -z "$INTELLIJ_ENVIRONMENT_READER" ]; then
              exec ${fishExe}
            fi
          fi
        '';
      };
      bash = {
        enable = true;

        # This is appended to ~/.bashrc (interactive shells)
        initExtra = ''
          # Only for interactive shells
          case $- in
            *i*)
              exec ${fishExe}
              ;;
          esac
        '';
      };
      home-manager.enable = true;

      k9s.enable = true;

      # stateVersion >= 26.05 defaults this to null on darwin, falling back to the
      # system man, which cannot search nix-installed pages. Keep man-db so that
      # `apropos` / `man -k` work; fish enables generateCaches to populate them.
      man.package = pkgs.man-db;
      starship = {
        enable = true;
        settings = lib.importTOML ./dotfiles/starship.toml;
      };

      yt-dlp.enable = true;

      kitty = lib.mkIf (!config.local.headless) {
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

      chromium = lib.mkIf (!pkgs.stdenv.isDarwin && !config.local.headless) {
        enable = true;
        extensions = [
          { id = "fmkadmapgofadopljbjfkapdkoienihi"; } # React DevTools
          { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; } # uBlock Origin
        ];
        dictionaries = [ pkgs.hunspellDictsChromium.en_US ];
      };
    };

    home = {

      # https://github.com/nix-community/home-manager/issues/1341
      activation.link-apps = lib.hm.dag.entryAfter [ "linkGeneration" ] (
        lib.optionalString pkgs.stdenv.isDarwin ''
          new_nix_apps="${config.home.homeDirectory}/Applications/Nix"
          rm -rf "$new_nix_apps"
          mkdir -p "$new_nix_apps"
          find -H -L "$newGenPath/home-files/Applications" -name "*.app" -type d -print | while read -r app; do
            real_app=$(readlink -f "$app")
            app_name=$(basename "$app")
            target_app="$new_nix_apps/$app_name"
            echo "Alias '$real_app' to '$target_app'"
            ${lib.getExe pkgs.mkalias} "$real_app" "$target_app"
          done
        ''
      );

      enableNixpkgsReleaseCheck = false;

      # mkDefault so the NixOS/nix-darwin module wins: it derives both from
      # users.users.<name> at normal priority, and two normal-priority
      # definitions would be a conflict. Standalone, nothing else defines them
      # and these apply.
      username = lib.mkDefault username;

      # Home directory differs between Darwin and Linux
      homeDirectory = lib.mkDefault (
        if pkgs.stdenv.isDarwin then "/Users/${username}" else "/home/${username}"
      );
      stateVersion = "26.05";

      # Packages common to both Darwin and Linux
      packages =
        commonPackages
        ++ lib.optionals (!pkgs.stdenv.isDarwin) linuxOnlyPackages
        ++ lib.optionals (!pkgs.stdenv.isDarwin && !config.local.headless) linuxGuiPackages
        ++ lib.optionals pkgs.stdenv.isDarwin darwinOnlyPackages;

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
          # npm/pnpm install global binaries into <prefix>/bin, so this has to be
          # ~/.local (not ~/.local/lib) for them to land on PATH.
          prefix=${config.home.homeDirectory}/.local

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

      # Rendered into hm-session-vars for every shell. The nix installer already
      # does this from /etc/zshrc on darwin, but that is zsh-only and host
      # specific -- fish as a login shell, or bash over ssh on Linux, would not
      # otherwise see the profile.
      sessionPath = [ "$HOME/.nix-profile/bin" ];
    };

    # stateVersion >= 25.11 flips macOS apps from linkApps to copyApps: real copies
    # (~1.6G) gated behind the App Management TCC permission, which hard-fails over
    # SSH. Keep linkApps -- the `link-apps` activation above already makes the apps
    # Spotlight-visible via mkalias, and it reads `home-files/Applications`, which
    # only exists while linkApps is enabled.
    targets.darwin = {
      copyApps.enable = false;
      linkApps.enable = true;
    };

    nixpkgs.config = {
      allowUnfree = true;
      cudaSupport = false;
    };
  };
}
