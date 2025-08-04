flakeInputs: self: super: 

let 
    hobiemon = super.callPackage "${flakeInputs.hobiemon}/default.nix" { }; 

in {
  inherit hobiemon; 
}