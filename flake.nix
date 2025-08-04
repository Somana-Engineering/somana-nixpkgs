{
    description = "Will's local nixpkgs"; 

    inputs = {
        nixpkgs.url = "git+ssh://git@github.com/NixOS/nixpkgs?ref=refs/tags/24.11";

        flake-utils.url = "github:numtide/flake-utils"; 

        flake-compat.url = "github:edolstra/flake-compat"; 
    
        ## Your Packages ## 
        
        # pkg.url = "git+ssh://<URL>"; 
        # pkgs.flake = false; <- Only if it is a nix flake

        ## Other Packages ## 

        rpi-builders.url = "git+ssh://github.com/nix-community/raspberry-pi-nix?rev=0ed819e708af17bfc4bbc63ee080ef308a24aa42"; 
        rpi-builders.flake = false; 

        nixos-hardware.url = "git+ssh://github.com/NixOS/nixos-hardware"; 
        nixos-hardware.flake = false; 
    
    }; 

    outputs = {self, flake-compat, flake-utils, nixpkgs, rpi-builders, ...} @ flakeInputs: 
    let 

      systems = [ "x86_64-linux" ]; 
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
      localModules = [./pkgs/top-level/modules.nix]; 
    
      lib = nixpkgs.lib.extend (
          final: prev: 
          {
              inherit localModules; 
              defaultConfig.allowUnfree = true; 
          }
      ); 
    in {
        # inherit localModules lib; 


        localOverlay =  import ./top-level.nix flakeInputs;

        legacyPackages = forAllSystems (
            system: 
            import nixpkgs {
                inherit system; 
                overlays = [localOverlay]; 
                config = lib.defaultConfig; 
            }
        );
        
        nixosModules = {
            default = 
            { ... }:
            {
                imports = localModules; 
            }; 
        }; 

        # aarch64linux = [ "aarch64-linux" ]; 
        # crossPackages nixpkgs.lib.genAttrs aarch64linux (system: )
        # = import nixpkgs {
            
        # }

        machines = {
            rpi-hobiemon = flakeInputs.nixpkgs.lib.nixosSystem {
            system = "aarch64-linux";
            modules = [ ./machines/rpi.nix ];
            };
        };
    };
}
