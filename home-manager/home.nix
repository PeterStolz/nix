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
    minikube
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
    # Bare on purpose: withPackages builds from source on darwin, and uv covers
    # per-project environments anyway.
    python312
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
    trivy
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
    # Linux-only in nixpkgs (meta.platforms), so it cannot live in commonPackages.
    singularity
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
  ]
  # Untracked per-user overrides, for boxes shared by several people. The
  # HM_GIT_* variables cannot cover that case: they are read from
  # /etc/environment, which is system-wide, so every user on the machine would
  # get the same commit author. A local.nix is per-home, and being untracked it
  # keeps `git pull --ff-only` working.
  ++ lib.optional (builtins.pathExists ./local.nix) ./local.nix;

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
        # straight into fish, so none of that zsh setup work is wasted. Preserve
        # commands passed with `zsh -c` so environment readers can inspect the
        # configured login environment instead of losing their command to fish.
        initContent = lib.mkBefore ''
          if [[ -o interactive && -z "$ZSH_EXECUTION_STRING" ]]; then
            if [ -z "$INTELLIJ_ENVIRONMENT_READER" ]; then
              exec ${fishExe}
            fi
          fi
        '';
      };
      bash = {
        enable = true;

        # Lands at the top of ~/.bashrc, above the `[[ $- == *i* ]] || return`
        # guard -- unlike initExtra, which lands below it. `ssh host <cmd>` is
        # neither interactive nor a login shell, so ~/.profile never runs and
        # sessionPath/sessionVariables would be invisible to it. Bash does read
        # ~/.bashrc there (stdin is a socket). The file self-guards against
        # double-sourcing and prints nothing, so scp/sftp stay safe.
        bashrcExtra = ''
          if [ -f "${config.home.profileDirectory}/etc/profile.d/hm-session-vars.sh" ]; then
            . "${config.home.profileDirectory}/etc/profile.d/hm-session-vars.sh"
          fi
        '';

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
          tab_title_template "{fmt.fg.red}{bell_symbol}{activity_symbol}{fmt.fg.tab}{tab.last_focused_progress_percent}{title}{' [{}]'.format(num_window_groups) if num_window_groups > 1 else str()}"
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
        # Keep this npm-only. pnpm reads .npmrc too, but npm warns on every key
        # it does not recognise ("Unknown user config"), which pollutes the
        # stderr of any tool shelling out to npm. pnpm settings go in
        # config.yaml below instead.
        ".npmrc".text = ''
          # npm installs global binaries into <prefix>/bin, so this has to be
          # ~/.local (not ~/.local/lib) for them to land on PATH.
          prefix=${config.home.homeDirectory}/.local
        '';

        # pnpm's global config. npm never reads it, so pnpm-only settings here
        # stay invisible to npm. Path is platform specific -- pnpm resolves it
        # per-OS, not via XDG on darwin. Keys are camelCase, unlike .npmrc.
        # Note this is a store symlink, so `pnpm config set --global` cannot
        # write to it; edit here instead.
        "${if pkgs.stdenv.isDarwin then "Library/Preferences" else ".config"}/pnpm/config.yaml".text = ''
          # Supply-chain hardening: refuse anything published <7 days ago.
          # https://pnpm.io/settings#minimumReleaseAge
          minimumReleaseAge: 10080
        '';
        ".config/uv/uv.toml".text = ''
          # Supply-chain hardening: ignore packages published in the last 7 days.
          # https://docs.astral.sh/uv/reference/settings/#exclude-newer
          exclude-newer = "7 days"
        '';
      };

      # Both render into hm-session-vars: sourced by fish itself, by ~/.profile
      # for login shells, and by bashrcExtra above for `ssh host <cmd>`. The nix
      # installer covers .nix-profile/bin but knows nothing about ~/.local/bin,
      # where npm/pnpm (see .npmrc) and self-installers like claude land.
      sessionVariables = {
        # Disable T3 Code's PostHog product telemetry.
        T3CODE_TELEMETRY_ENABLED = "false";
      };

      sessionPath = [
        "$HOME/.local/bin"
        "$HOME/.nix-profile/bin"
      ];
    };

    # stateVersion >= 25.11 flips macOS apps from linkApps to copyApps: real copies
    # (~1.6G) gated behind the App Management TCC permission, which hard-fails over
    # SSH. Keep linkApps -- the `link-apps` activation above already makes the apps
    # Spotlight-visible via mkalias, and it reads `home-files/Applications`, which
    # only exists while linkApps is enabled.
    # mkIf, not a bare attrset: the module asserts on non-darwin platforms, so
    # setting linkApps.enable at all breaks eval on Linux.
    targets.darwin = lib.mkIf pkgs.stdenv.isDarwin {
      copyApps.enable = false;
      linkApps.enable = true;
    };

    nixpkgs.config = {
      allowUnfree = true;
      cudaSupport = false;
    };
  };
}
