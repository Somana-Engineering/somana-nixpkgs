inputs: {
  orin-base = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      inputs.self.nixosModules.default
      { nixpkgs.buildPlatform = "x86_64-linux"; }
      ./orin
    ];
  };
  rpi = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      inputs.self.nixosModules.default
      {
        nixpkgs.hostPlatform = "aarch64-linux";
        nixpkgs.buildPlatform = "x86_64-linux";
      }
      ./rpi
    ];
  };
}
