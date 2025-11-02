{
    description = "Will's local nixpkgs"; 

    inputs = {
        nixpkgs.url = "git+ssh://git@github.com/NixOS/nixpkgs?ref=refs/tags/24.11";

        flake-utils.url = "github:numtide/flake-utils"; 

        flake-compat.url = "github:edolstra/flake-compat"; 
    
        ## Your Packages ## 
        
        # pkg.url = "git+ssh://<URL>"; 
        # pkgs.flake = false; <- Only if it is a nix flake

        # somana-agent.url = "git+ssh://github.com/Somana-Engineering/somana-agent"; 
        # somana-agent.flake = false; 

        ## Other Packages ## 

        git.url = "git+ssh://git@github.com/git/git"; 

        nixos-hardware.url = "git+ssh://git@github.com/NixOS/nixos-hardware"; 
        jetpack.url = "git+ssh://git@github.com/anduril/jetpack-nixos"; 
        jetpack.inputs.nixpkgs.follows = "nixpkgs"; 
    
    }; 

    outputs = {self, flake-compat, flake-utils, nixpkgs, jetpack, ...} @ flakeInputs: 
    let 
      ## Supported OS Types
      systems = [ "x86_64-linux" "aarch64-linux" ]; 

      ## Functions for Building / Creating Pkgs
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
      callPackage = set: f: overrides: f ((builtins.intersectAttrs (builtins.functionArgs f) set) // overrides);   
      
      ## Builder functions to reduce length of build calls (default = config.system.build.toplevel)
      arm-builder = import ./machines/builder.nix "aarch64-linux" [{
                    nixpkgs.config = lib.defaultConfig;
                }];
      x86-builder = import ./machines/builder.nix "x86_64-linux" [];
      


      localModules = [./pkgs/top-level/modules.nix]; 
    
      lib = nixpkgs.lib.extend (
          final: prev: 
          {
              inherit localModules; 
              defaultConfig.allowUnfree = true; 
          }
      ); 

    localOverlay =  import ./top-level.nix flakeInputs;

    pkgs = import nixpkgs { system = "x86_64-linux"; };
    pkgsAarch64 = import nixpkgs { system = "aarch64-linux"; };

    iso = (pkgsAarch64.nixos {
      imports = [ "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-base.nix" ];
    }).config.system.build.isoImage;


    in {
        # inherit localModules lib;

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

        machine-defs = import ./machines/orin/orin-kits.nix

        # Machine definitions 
        machines = {
            orin-base = nixpkgs.lib.nixosSystem {
                system = "aarch64-linux";
                modules = [
                    ./machines/orin.nix
                ];
                specialArgs = { inherit flakeInputs; };
            };
            rpi-base = arm-builder { inputModules = [ ./machines/rpi.nix ]; nixpkgs = flakeInputs.nixpkgs; flakeInputs = flakeInputs; }; 
            orin-base-broken = arm-builder { inputModules = [ ./machines/orin.nix ]; nixpkgs = flakeInputs.nixpkgs; flakeInputs = flakeInputs; }; 
            navkit-custom = arm-builder {inputModules = [machine-defs.navkit-custom]}; 
        
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

        
        # ## This isn't working quite yet, but will simplify building packages so that they all build the same way
        # xpkgs-rpi = xpkgs-builder {
        #     inputModules = [
        #         flakeInputs.nixos-hardware.nixosModules.raspberry-pi-4 
        #         ./machines/rpi.nix 
        #     ]; 
        #     nixpkgs = flakeInputs.nixpkgs; 
        # }; 
    };
}
