inputs: {
  default = {
    imports = [
      ./somana-agent
      inputs.jetpack-nixos.nixosModules.default
      { nixpkgs.overlays = [ inputs.self.overlays.default ]; }
    ];
  };
}
