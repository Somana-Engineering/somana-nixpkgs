{
  description = "Somana nix expressions";

  inputs = {
    jetpack-nixos.inputs.nixpkgs.follows = "nixpkgs";
    jetpack-nixos.url = "github:anduril/jetpack-nixos";
    nixpkgs.url = "github:NixOS/nixpkgs/release-25.05";
  };

  outputs = inputs: {
    legacyPackages = import ./legacy-packages inputs;
    nixosConfigurations = import ./nixos-configurations inputs;
    nixosModules = import ./nixos-modules inputs;
    overlays = import ./overlays inputs;
  };
}
