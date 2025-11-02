{ config, pkgs, lib, flakeInputs, nixos-hardware, ... }:
let
  hostname = "pinix";
  user = "tempuser";
  password = "somepass";
  nixosHardwareVersion = "7f1836531b126cfcf584e7d7d71bf8758bb58969";
  timeZone = "UTC";
  defaultLocale = "UTC";
  kernelBundle = pkgs.linuxAndFirmware.v6_6_31;
in {

  imports = [
    ../pkgs/modules/nice-looking-console.nix
  ]; 

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
  networking.defaultGateway = {
    address = "192.168.1.0";
    interface = "eth0"; 
  }; 
  networking.nameservers = [ "8.8.8.8" ];
  networking.networkmanager.unmanaged = [ "interface-name:wlan*" ]
    ++ lib.optional config.services.hostapd.enable
    "interface-name:${config.services.hostapd.interface}";

  networking.useNetworkd = true;
  networking.firewall.allowedUDPPorts = [ 5353 ];
  systemd.network.networks = {
      "99-ethernet-default-dhcp".networkConfig.MulticastDNS = "yes";
      "99-wireless-client-dhcp".networkConfig.MulticastDNS = "yes";
  };


  services.udev.extraRules = ''
    # Ignore partitions with "Required Partition" GPT partition attribute
    # On our RPis this is firmware (/boot/firmware) partition
    ENV{ID_PART_ENTRY_SCHEME}=="gpt", \
    ENV{ID_PART_ENTRY_FLAGS}=="0x1", \
    ENV{UDISKS_IGNORE}="1"
  '';

  environment.systemPackages = with pkgs; [ curl vim tree ];
  services.openssh.enable = true;
  time.timeZone = timeZone;
  users = {
    mutableUsers = false;
    users."root".initialHashedPassword = "";
    users."${user}" = {
      isNormalUser = true;
      password = password;
      extraGroups = [ "wheel" ];
    };
    users."nixos" = {
          isNormalUser = true;
          extraGroups = [
            "wheel"
            "networkmanager"
            "video"
          ];
          # Allow the graphical user to login without password
          initialHashedPassword = "";
        };
  };
  networking.wireless.enable = false;
   networking.hostId = "8821e309";
  # This is required for this to build for some reason...
  networking.wireless.iwd = {
          enable = true;
          settings = {
            Network = {
              EnableIPv6 = true;
              RoutePriorityOffset = 300;
            };
            Settings.AutoConnect = true;
          };
        };

  nix.settings.trusted-users = [ "nixos" ];

  systemd.services = {
        systemd-networkd.stopIfChanged = false;
        # Services that are only restarted might be not able to resolve when resolved is stopped before
        systemd-resolved.stopIfChanged = false;
    };
  # Enable passwordless sudo. 
   security.sudo = {
          enable = true;
          wheelNeedsPassword = false;
          extraRules= [ { users = [ user ]; commands = [ { command = "ALL" ; options= [ "NOPASSWD" ]; } ]; } ];
        };
   services.getty.autologinUser = "nixos";
  boot = {
    tmp.useTmpfs = true;
    loader.raspberryPi.firmwarePackage = kernelBundle.raspberrypifw;
    loader.raspberryPi.bootloader = "kernel";
    kernelPackages = kernelBundle.linuxPackages_rpi5;
  };

  # Not sure what this does yet 
  nixpkgs.overlays = lib.mkAfter [
        (self: super: {
        # This is used in (modulesPath + "/hardware/all-firmware.nix") when at least 
        # enableRedistributableFirmware is enabled
        # I know no easier way to override this package
        inherit (kernelBundle) raspberrypiWirelessFirmware;
        # Some derivations want to use it as an input,
        # e.g. raspberrypi-dtbs, omxplayer, sd-image-* modules
        inherit (kernelBundle) raspberrypifw;
        })
    ];

  security.polkit.enable = true;

  # Set System information
  system.nixos.tags = let
    cfg = config.boot.loader.raspberryPi;
    in [
        "raspberry-pi-${cfg.variant}"
        cfg.bootloader
        config.boot.kernelPackages.kernel.version
    ];
    system.stateVersion = config.system.nixos.release;
}
