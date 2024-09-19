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
    networkmanager.enable = true;
    firewall = {
      enable = true;
      allowedTCPPorts = [ 443 ];
    };
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
    fish
    home-manager
    python311
    python311Packages.pip
    wget
    git
    nixfmt-rfc-style
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
}
