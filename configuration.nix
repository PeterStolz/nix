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
    ./home-manager/default.nix
  ];

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
    kitty
    fish
    home-manager
    python311
    python311Packages.torch-bin
    python311Packages.torchaudio-bin
    python311Packages.torch-audiomentations
    python311Packages.librosa
    python311Packages.jiwer
    python311Packages.datasets
    python311Packages.transformers
    python311Packages.evaluate
    python311Packages.accelerate
    python311Packages.pip
    wget
    git
    nixfmt-rfc-style
  ];

  # Program configurations
  programs.firefox.enable = true;
  programs.fish.enable = true;
  programs.neovim = {
    enable = true;
    defaultEditor = true;
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

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # System version
  system.stateVersion = "24.05";
}
