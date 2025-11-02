flakeInputs: self: super: 

let 

in {
    arm-builder = super.callPackage {
                nixpkgs = super.nixpkgs; 
            }; 

    somana-agent = super.callPackage ${flakeInputs.somana-agent}/default.nix {}; 
}