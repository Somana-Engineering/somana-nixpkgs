inputs: {
  default = {
    imports = [
      ./somana-agent
      inputs.jetpack-nixos.nixosModules.default
      { 
        nixpkgs.overlays = [
          inputs.self.overlays.default
          inputs.nix-ros-overlay.overlays.default
        ];
      }
    ];
  };
}
