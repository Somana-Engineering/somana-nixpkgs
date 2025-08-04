{overlays ? [], config ? {}, ...}@args: 
let
    lock = builtins.fromJSON(builtins.readFile ./flake.lock); 
    flake-compat = builtins.fetchTarball {
        url = "https://github.com/edolstra/flake-compat/archive/${lock.nodes.flake-compat.locked.rev}.tar.gz"; 
        sha256 = lock.nodes.flake-compat.locked.narHash; 
    }; 

    inherit ((import flake-compat {src = ./.; }).defaultNix) inputs outputs;
    nixpkgs = inputs.nixpkgs;  
    pkgs = import nixpkgs (args // {
        config = config // {
            allowUnfree = true; 
        }; 
        # overlays = (import ./overlays.nix outputs.overlays) ++ overlays ++ [ (import ./top-level.nix inputs)];
        # overlays = overlays;
        overlays = [ (import ./top-level.nix inputs)];
    }); 
in pkgs