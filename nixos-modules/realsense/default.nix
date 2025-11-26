{ config, lib, pkgs, ... }:

let
  cfg = config.hardware.realsense;
in
{
  options.hardware.realsense = {
    enable = lib.mkEnableOption "Intel RealSense camera support";
  };

  config = lib.mkIf cfg.enable {
    # Add udev rules for device access (librealsense package includes these)
    services.udev.packages = [ pkgs.librealsense ];

    # Add librealsense to system packages (equivalent to nix shell nixpkgs#librealsense)
    environment.systemPackages = [ pkgs.librealsense ];

    # RealSense cameras typically use USB Video Class driver
    # The uvcvideo module is usually built into the kernel, but we can ensure it's loaded
    boot.kernelModules = [ "uvcvideo" ];
  };
}

