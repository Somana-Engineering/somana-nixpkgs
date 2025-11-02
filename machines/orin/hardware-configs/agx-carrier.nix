{ config, pkgs, lib, flakeInputs, ... }:
let
in {
  imports = [
    ../orin-common.nix
  ];

  hardware.nvidia-jetpack.som = "agx";
  hardware.nvidia-jetpack.carrier = "devkit"; 

  hardware.nic = "BMX2002"; 

  
}