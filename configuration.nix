{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    <home-manager/nixos>
  ];
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.cudaSupport = true;

  # Bootloader configuration
  boot.loader.grub = {
    enable = true;
    device = "/dev/nvme1n1";
    useOSProber = true;
  };

  # Networking
  networking = {
    hostName = "nixos";
    nameservers = [
      "127.0.0.1"
      "::1"
    ];
    networkmanager = {
      enable = true;
      dns = "none";
    };
    firewall = {
      enable = true;
      allowedTCPPorts = [
        22
        443
      ];
    };
    resolvconf.useLocalResolver = true;
  };

  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings = {
      PasswordAuthentication = false;
      AllowUsers = null; # Allows all users by default. Can be [ "user1" "user2" ]
      UseDns = true;
      X11Forwarding = false;
      PermitRootLogin = "no"; # "yes", "without-password", "prohibit-password", "forced-commands-only", "no"
    };
  };

  services.tailscale.enable = true;

  services.pcscd.enable = true;
  programs.gnupg.agent = {
    pinentryPackage = pkgs.pinentry-curses;
    enable = true;
    enableSSHSupport = true;
  };

  services.dnscrypt-proxy2 = {
    enable = true;
    settings = {
      ipv6_servers = true;
      require_dnssec = true;
      forwarding_rules = "/etc/nixos/networking/forwarding-rules.txt";

      sources.public-resolvers = {
        urls = [
          "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/public-resolvers.md"
          "https://download.dnscrypt.info/resolvers-list/v3/public-resolvers.md"
        ];
        cache_file = "/var/lib/dnscrypt-proxy2/public-resolvers.md";
        minisign_key = "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
      };

      # You can choose a specific set of servers from https://github.com/DNSCrypt/dnscrypt-resolvers/blob/master/v3/public-resolvers.md
      # TODO troubleshoot why this is (probably) not working. Tcpdump did not query to 1.1.1.1 or 1.0.0.1
      server_names = [ "cloudflare" ];
    };
  };

  systemd.services.dnscrypt-proxy2.serviceConfig = {
    StateDirectory = "dnscrypt-proxy";
  };

  # Time zone and localization
  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_DE.UTF-8";
    LC_IDENTIFICATION = "de_DE.UTF-8";
    LC_MEASUREMENT = "de_DE.UTF-8";
    LC_MONETARY = "de_DE.UTF-8";
    LC_NAME = "de_DE.UTF-8";
    LC_NUMERIC = "de_DE.UTF-8";
    LC_PAPER = "de_DE.UTF-8";
    LC_TELEPHONE = "de_DE.UTF-8";
    LC_TIME = "de_DE.UTF-8";
  };

  # X11 and KDE Plasma
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;
  services.xserver = {
    enable = true;
    xkb = {
      layout = "us";
      variant = "";
    };
  };

  # Printing
  services.printing.enable = true;

  # Sound
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Virtualization
  virtualisation.docker = {
    enable = true;
    # enableNvidia = true;
  };

  # User configuration
  users.defaultUserShell = pkgs.bash;
  home-manager.users.peter = import ./home-manager/home.nix;
  users.users.peter = {
    isNormalUser = true;
    description = "peter";
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
    ];
    packages = with pkgs; [ kdePackages.kate ];
  };

  # System packages
  environment.systemPackages = with pkgs; [
    gnupg
    pinentry-curses
    fish
    home-manager
    python311
    python311Packages.pip
    wget
    git
    nixfmt-rfc-style
    tcpdump
    # nvidia-docker
  ];

  # Program configurations
  programs.fish.enable = true;
  programs.bash = {
    interactiveShellInit = ''
      if [[ $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "fish" && -z ''${BASH_EXECUTION_STRING} ]]
      then
        shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
        exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
      fi
    '';
  };

  # https://github.com/mcdonc/.nixconfig/blob/e7885ad18b7980f221e59a21c91b8eb02795b541/videos/pydev/script.rst
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc.lib
    zlib # numpy
  ];

  programs.neovim = {
    viAlias = true;
    vimAlias = true;
    enable = true;
    defaultEditor = true;
    withNodeJs = true;
    withPython3 = true;
    configure = {
      customRC = ''
        set number relativenumber
        set tabstop=2 shiftwidth=2 expandtab
        syntax enable

        autocmd BufRead,BufNewFile Tiltfile set filetype=python

        set list listchars=eol:$
        colorscheme gruvbox
      '';
      packages.myVimPackage = with pkgs.vimPlugins; {
        # loaded on launch
        start = [ gruvbox ];
        # manually loadable by calling `:packadd $plugin-name`
        opt = [ ];
      };
    };
  };

  # Nvidia configuration
  hardware.opengl.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia-container-toolkit.enable = true;
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.production;
  };

  # System version
  system.stateVersion = "24.05";

  security = {
    apparmor.enable = true;
    # lockKernelModules = true;
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
  };
}
