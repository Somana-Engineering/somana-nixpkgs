{
  description = "Somana nix expressions";

  inputs = {
    jetpack-nixos.inputs.nixpkgs.follows = "nixpkgs";
    jetpack-nixos.url = "github:anduril/jetpack-nixos";
    nixpkgs.url = "github:NixOS/nixpkgs/release-25.05";
    nix-ros-overlay.url = "github:lopsided98/nix-ros-overlay";
  };

  outputs = inputs: {
    legacyPackages = import ./legacy-packages inputs;
    nixosConfigurations = import ./nixos-configurations inputs;
    nixosModules = import ./nixos-modules inputs;
    overlays = import ./overlays inputs;
  };
}
