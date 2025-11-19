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

    (with rosPackages.jazzy; buildEnv {
      name = "ros-jazzy-env";
      paths = [
        ros-core
        ros-base
        # add more ROS packages here if you want (rviz2, rosbag2, etc.)
      ];
    })
  ];
  
  # Boot configuration handled by JetPack module

  # # GPU support (recommended)
  # hardware.graphics.enable = true;

  # ROS 2 Environment
  environment.variables = {
    ROS_DISTRO = "jazzy";
    ROS_VERSION = "2";
  };

 
  # System state
  system.stateVersion = "25.05"; # Match your working system

  services.sprinter-agent = {
    enable = true;
    sprinterUrl = "http://3.14.12.179:8080";
  };
  
  services.tailscale.enable = true;
}
