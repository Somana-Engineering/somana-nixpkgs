{
  description = "Somana nix expressions";

  inputs = {
    jetpack-nixos.inputs.nixpkgs.follows = "nixpkgs";
    jetpack-nixos.url = "github:anduril/jetpack-nixos";
    nixpkgs.url = "github:NixOS/nixpkgs/release-25.05";
    nix-ros-overlay.url = "github:lopsided98/nix-ros-overlay";
    nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi"; 
  };

  nixConfig = {
    extra-substituters = [
      "https://nixos-raspberrypi.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
    ];
  };

  outputs = inputs: {
    hydraJobs = import ./hydra-jobs inputs;
    legacyPackages = import ./legacy-packages inputs;
    nixosConfigurations = import ./nixos-configurations inputs;
    nixosModules = import ./nixos-modules inputs;
    overlays = import ./overlays inputs;
  };
}
