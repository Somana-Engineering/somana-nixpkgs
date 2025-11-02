# .. Common hardware + sw configs for all orins

{ config, pkgs, lib, flakeInputs, ... }:
let
  hostname = "orin";
  user = "nixos";
  password = "nixos";
  timeZone = "America/New_York";
  defaultLocale = "en_US.UTF-8";
in {
  imports = [

  ];
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

}