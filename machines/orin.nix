{ config, pkgs, lib, flakeInputs, ... }:
let
  hostname = "orin";
  user = "somana";
  password = "somana";
  timeZone = "America/New_York";
  defaultLocale = "en_US.UTF-8";
in {
  imports = [
    flakeInputs.jetpack.nixosModules.default
    ./hardware/orin-hardware.nix
  ];

  # Enable JetPack support
  hardware.nvidia-jetpack.enable = true;
  hardware.nvidia-jetpack.som = "orin-agx";      # use orin-agx for AGX Orin
  hardware.nvidia-jetpack.carrierBoard = "devkit";

  # File systems and networking are handled by hardware-configuration.nix

  # Networking
  networking.hostName = hostname;

  # System packages
  environment.systemPackages = with pkgs; [
    curl
    vim
    git
    htop
    tmux
    # CUDA/GPU tools
    cudatoolkit
    # cudnn  # Temporarily disabled - package not found
  ];

  # Services
  services.openssh = {
    enable = true;
    permitRootLogin = "yes";
    passwordAuthentication = true;
  };

  # Time zone
  time.timeZone = timeZone;
  i18n.defaultLocale = defaultLocale;

  # Users
  users = {
    mutableUsers = false;
    users."${user}" = {
      isNormalUser = true;
      password = password;
      extraGroups = [ "wheel" "docker" "video" ];
    };
    users.root = {
      password = "somana";
    };
  };

  # Enable passwordless sudo
  security.sudo.extraRules = [
    {
      users = [ user ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  # Boot configuration for Jetson
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # GPU support (recommended)
  hardware.graphics.enable = true;

  # System state
  system.stateVersion = "25.05"; # Match your working system
}
