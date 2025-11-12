{ config, ... }:
{
  imports = [ ./hardware.nix ];

  boot.loader.systemd-boot.enable = true;

  # Enable JetPack support
  hardware.nvidia-jetpack.enable = true;
  hardware.nvidia-jetpack.som = "orin-agx"; # use orin-agx for AGX Orin
  hardware.nvidia-jetpack.carrierBoard = "devkit";

  # File systems and networking are handled by hardware-configuration.nix

  # Networking
  networking.hostName = "orin";

  # Services
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = true;
    };
  };

  # Time zone
  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";

  # Users
  users = {
    mutableUsers = false;
    users.nixos = {
      isNormalUser = true;
      password = "nixos";
      extraGroups = [
        "wheel"
        "docker"
        "video"
      ];
    };
    users.root.password = "nixos";
  };

  # Enable passwordless sudo
  security.sudo.extraRules = [
    {
      users = [ config.users.users.nixos.name ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  # Boot configuration handled by JetPack module

  # # GPU support (recommended)
  # hardware.graphics.enable = true;

  # System state
  system.stateVersion = "25.05"; # Match your working system

  services.somana-agent.enable = true;
}
