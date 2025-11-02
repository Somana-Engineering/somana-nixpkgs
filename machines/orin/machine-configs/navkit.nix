{ config, pkgs, lib, flakeInputs, ... }:
let
in {
  imports = [
    # flakeInputs.jetpack.nixosModules.default  # Temporarily disabled due to compatibility issues
    ./hardware/orin-hardware.nix
  ];

  nav.enable = true; 
  nav.imu = "SDI505"; 
  nav.gps = "mosaic"; 


}