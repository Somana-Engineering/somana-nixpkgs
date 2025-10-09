{ config, pkgs, lib, flakeInputs, nixos-hardware, ... }:
let
  hostname = "pinix";
  user = "tempuser";
  password = "somepass";
  nixosHardwareVersion = "7f1836531b126cfcf584e7d7d71bf8758bb58969";
  timeZone = "America/New_York";
  defaultLocale = "en_US.UTF-8";
in {
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
      options = [ "noatime" ];
    };
  };
  networking.hostName = hostname;
  networking.interfaces.eth0.ipv4.addresses = [{
    address = "192.168.167.1";
    prefixLength = 24;
  }];
  networking.defaultGateway = "192.168.1.0";
  networking.nameservers = [ "8.8.8.8" ];
  networking.networkmanager.unmanaged = [ "interface-name:wlan*" ]
    ++ lib.optional config.services.hostapd.enable
    "interface-name:${config.services.hostapd.interface}";

  # Ability to add a network bridge interface
  # networking.bridges.br0.interfaces = [ "eth0" "wlan0" ];
  environment.systemPackages = with pkgs; [ curl vim ];
  services.openssh.enable = true;
  time.timeZone = timeZone;
  users = {
    mutableUsers = false;
    users."${user}" = {
      isNormalUser = true;
      password = password;
      extraGroups = [ "wheel" ];
    };
  };
  # Enable passwordless sudo. 
  security.sudo.extraRules= [ { users = [ user ]; commands = [ { command = "ALL" ; options= [ "NOPASSWD" ]; } ]; } ];
  # Enable GPU acceleration 
  # hardware.raspberry-pi."4".fkms-3d.enable = true;
  services.xserver = {
    enable = true;
  };
  boot.loader = {
  efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot/efi";
    };
    grub = {
      efiSupport = true;
      device = "nodev";
    };
  };

  system.stateVersion = "23.11";
}
