flakeInputs: self: super: 

let 

in {
    arm-builder = super.callPackage {
                nixpkgs = super.nixpkgs; 
            }; 
}