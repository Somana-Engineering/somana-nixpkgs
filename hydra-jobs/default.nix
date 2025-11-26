inputs:

let
  inherit (inputs.nixpkgs.lib)
    const
    mapAttrs
    ;
in

{
  nixos = mapAttrs (const (nixosConfig: {
    inherit (nixosConfig.config.system.build) toplevel;
  })) inputs.self.nixosConfigurations;
}
