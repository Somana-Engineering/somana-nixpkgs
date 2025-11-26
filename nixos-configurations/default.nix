inputs: {
  orin-base = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      inputs.self.nixosModules.default
      { 
	nixpkgs.buildPlatform = "aarch64-linux";
      }
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
  rpi5 = inputs.nixos-raspberrypi.lib.nixosSystem {
    specialArgs = inputs; 
    modules = [
      {
      imports = with inputs.nixos-raspberrypi.nixosModules; [
          raspberry-pi-5.base
          raspberry-pi-5.page-size-16k
        ];
      }	
      ./rpi
    ];
  }; 
}
