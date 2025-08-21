{
    description = "Will's local nixpkgs"; 

    inputs = {
        nixpkgs.url = "git+ssh://git@github.com/NixOS/nixpkgs?ref=refs/tags/25.05";

        flake-utils.url = "github:numtide/flake-utils"; 

        flake-compat.url = "github:edolstra/flake-compat"; 
    
        ## Your Packages ## 
        
        # pkg.url = "git+ssh://<URL>"; 
        # pkgs.flake = false; <- Only if it is a nix flake

        ## Other Packages ## 

        nixos-hardware.url = "git+ssh://git@github.com/NixOS/nixos-hardware"; 
        jetpack.url = "git+ssh://git@github.com/anduril/jetpack-nixos"; 
        jetpack.inputs.nixpkgs.follows = "nixpkgs"; 
    
    }; 

    outputs = {self, flake-compat, flake-utils, nixpkgs, jetpack, ...} @ flakeInputs: 
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

      # Cross-compilation configuration for Raspberry Pi
      crossSystem = {
        system = "aarch64-linux";
        config = "aarch64-unknown-linux-gnu";
        libc = "glibc";
        platform = {
          name = "linux";
          kernelMajor = "5";
          kernelHeadersBaseConfig = "defconfig";
          kernelAutoModules = true;
          kernelPreferBuiltin = true;
          kernelTarget = "Image";
          kernelArch = "arm64";
          kernelDTB = true;
          kernelBaseConfig = "defconfig";
          kernelMakeFlags = [];
          gcc = {
            arch = "armv8-a";
            tune = "generic";
            abi = "lp64";
            fpu = "neon-fp-armv8";
            float-abi = "hard";
          };
        };
      };

    localOverlay =  import ./top-level.nix flakeInputs;
    arm-builder = import ./machines/builder.nix "aarch64-linux" [];
    x86-builder = import ./machines/builder.nix "x86_64-linux" [];
    xpkgs-builder = import ./machines/builder.nix "aarch64-linux" [{
                            nixpkgs.crossSystem = crossSystem;
                            nixpkgs.overlays = [localOverlay];
                            nixpkgs.config = lib.defaultConfig;
                        }];  
    in {
        # inherit localModules lib;
        testInputs = flakeInputs;  

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

        # Base machine for raspberry pi. Can only be built on arm
        machines = {
            rpi-base = arm-builder { inputModules = [ ./machines/rpi.nix ]; nixpkgs = flakeInputs.nixpkgs; }; 
            orin-base = arm-builder { inputModules = [ ./machines/orin.nix ]; nixpkgs = flakeInputs.nixpkgs; }; 
        };

        # Cross-compiled for building on x86
        xpkgs-machines = {
            rpi = let
                system = flakeInputs.nixpkgs.lib.nixosSystem {
                    system = "aarch64-linux";
                    modules = [ 
                        flakeInputs.nixos-hardware.nixosModules.raspberry-pi-4
                        ./machines/rpi.nix 
                        {
                            nixpkgs.crossSystem = crossSystem;
                            nixpkgs.overlays = [localOverlay];
                            nixpkgs.config = lib.defaultConfig;
                        }
                    ];
                };
            in {
                system = system.config.system.build.toplevel;
                kernel = system.config.boot.kernelPackages.kernel;
                initrd = system.config.system.build.initialRamdisk;
                kernelModules = system.config.system.build.kernelModules;
            };
        }; 
        
        
        ## This isn't working quite yet, but will simplify building packages so that they all build the same way
        xpkgs-rpi = xpkgs-builder {
            inputModules = [
                flakeInputs.nixos-hardware.nixosModules.raspberry-pi-4 
                ./machines/rpi.nix 
            ]; 
            nixpkgs = flakeInputs.nixpkgs; 
        }; 
    };
}
