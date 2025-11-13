{ config, pkgs, ... }:
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
    users.somana = {
      isNormalUser = true;
      password = "somana";
      extraGroups = [
        "wheel"
        "docker"
        "video"
      ];
    };
    users.root.password = "somana";
  };

  # Enable passwordless sudo
  security.sudo.extraRules = [
    {
      users = [ config.users.users.somana.name ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
  
  environment.systemPackages = with pkgs; [
    vim
    git
    # ROS 2 Humble (LTS) - includes base ROS 2 packages and desktop tools
    rosPackages.humble.base
    rosPackages.humble.desktop
  ];
  # Boot configuration handled by JetPack module

  # # GPU support (recommended)
  # hardware.graphics.enable = true;

  # ROS 2 Environment
  environment.variables = {
    ROS_DISTRO = "humble";
    ROS_VERSION = "2";
  };

  # Automatically source ROS setup files in user shells
  programs.bash.interactiveShellInit = ''
    # Source ROS 2 Humble setup files if they exist
    if [ -f "${pkgs.rosPackages.humble.base}/setup.bash" ]; then
      source "${pkgs.rosPackages.humble.base}/setup.bash"
    fi
    if [ -f "${pkgs.rosPackages.humble.desktop}/setup.bash" ]; then
      source "${pkgs.rosPackages.humble.desktop}/setup.bash"
    fi
  '';

  # System state
  system.stateVersion = "25.05"; # Match your working system

  services.somana-agent = {
    enable = true;
    somanaUrl = "http://3.14.12.179:8080";
    hostId = "5";
  };
  
  services.tailscale.enable = true;
}
