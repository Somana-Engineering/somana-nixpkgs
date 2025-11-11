{
    description = "Will's local nixpkgs"; 

    inputs = {
        nixpkgs.url = "git+ssh://git@github.com/NixOS/nixpkgs?ref=refs/tags/25.05";

        flake-utils.url = "github:numtide/flake-utils"; 

        flake-compat.url = "github:edolstra/flake-compat"; 

        nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi/main";

        ## Your Packages ## 
        
        # pkg.url = "git+ssh://<URL>"; 
        # pkgs.flake = false; <- Only if it is a nix flake

        ## Other Packages ## 

        nixos-hardware.url = "git+ssh://git@github.com/NixOS/nixos-hardware"; 
        jetpack.url = "git+ssh://git@github.com/anduril/jetpack-nixos"; 
        jetpack.inputs.nixpkgs.follows = "nixpkgs"; 
    
    }; 

    nixConfig = {
        extra-substituters = [
            "https://nixos-raspberrypi.cachix.org"
        ];
        extra-trusted-public-keys = [
            "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
        ];
    };

    outputs = {self, flake-compat, flake-utils, nixpkgs, jetpack, nixos-raspberrypi, disko, ...} @ flakeInputs: 
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
    arm-builder = import ./machines/builder.nix "aarch64-linux" [{
                            nixpkgs.config = lib.defaultConfig;
                        }];
    x86-builder = import ./machines/builder.nix "x86_64-linux" [];
    xpkgs-builder = import ./machines/builder.nix "aarch64-linux" [{
                            nixpkgs.crossSystem = crossSystem;
                            nixpkgs.overlays = [localOverlay];
                            nixpkgs.config = lib.defaultConfig;
                        }];  

    callPackage = set: f: overrides: f ((builtins.intersectAttrs (builtins.functionArgs f) set) // overrides); 
    pkgs = import nixpkgs { system = "x86_64-linux"; };
    pkgsAarch64 = import nixpkgs { system = "aarch64-linux"; };

    iso = (pkgsAarch64.nixos {
      imports = [ "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-base.nix" ];
    }).config.system.build.isoImage;
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

        nixosConfigurations = {
            orin-base = nixpkgs.lib.nixosSystem {
                system = "aarch64-linux";
                modules = [
                    ./machines/orin.nix
                    ./machines/hardware/orin-hardware.nix
                ];
                specialArgs = { inherit flakeInputs; };
            };
        }; 

        # Base machines for ARM devices. Can only be built on arm
        machines = {
            rpi-base = arm-builder { inputModules = [ ./machines/rpi5.nix ]; nixpkgs = flakeInputs.nixpkgs; }; 
            rpi5-base = nixos-raspberrypi.lib.nixosSystemFull {
                specialArgs = flakeInputs;
                modules = [
                    {
                    imports = with nixos-raspberrypi.nixosModules; [
                        raspberry-pi-5.base
                        raspberry-pi-5.page-size-16k
                        raspberry-pi-5.display-vc4
                        raspberry-pi-5.bluetooth
                    ];
                }
                ./machines/rpi5.nix
		./pi5-configtxt.nix
                ];
            }; 
            orin-base = arm-builder { inputModules = [ ./machines/orin.nix ]; nixpkgs = flakeInputs.nixpkgs; }; 
        };

        # Cross-compiled for building on x86
        xpkgs-machines = {
            rpi = xpkgs-builder { inputModules = [ ./machines/rpi.nix ]; nixpkgs = flakeInputs.nixpkgs; flakeInputs = flakeInputs; }; 
            orin = xpkgs-builder { inputModules = [ ./machines/orin.nix ]; nixpkgs = flakeInputs.nixpkgs; flakeInputs = flakeInputs; }; 
        }; 
        
        vms = {
            arm-builder = pkgs.writeScriptBin "run-nixos-vm" ''
                #!${pkgs.runtimeShell}
                if [ -z $1 ]; then
                    echo "Please supply the qcow file for the vm" 
                    exit
                fi

                ${pkgs.qemu}/bin/qemu-system-aarch64 \
                    -machine virt,gic-version=max \
                    -cpu max \
                    -m 4G \
                    -smp 4 \
                    -drive file="/home/nixos/arm-builder.qcow2",if=virtio,format=qcow2 \
                    -drive file=$(echo ${iso}/iso/*.iso),format=raw,readonly=on \
                    -nographic \
                    -bios ${pkgsAarch64.OVMF.fd}/FV/QEMU_EFI.fd \
                    -net nic,model=virtio \
                    -net user,hostfwd=tcp::2222-:22
                '';
        };
        
        
        ## This isn't working quite yet, but will simplify building packages so that they all build the same way
        # xpkgs-rpi = xpkgs-builder {
        #     inputModules = [
        #         flakeInputs.nixos-hardware.nixosModules.raspberry-pi-4 
        #         ./machines/rpi.nix 
        #     ]; 
        #     nixpkgs = flakeInputs.nixpkgs; 
        # }; 

        
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
