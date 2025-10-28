system-type:
addModules: 
{
  inputModules, 
  nixpkgs,
  flakeInputs ? {}
}: 
let 
  system = nixpkgs.lib.nixosSystem {
    system = system-type;
    modules = if builtins.isList inputModules then inputModules ++ addModules else [ inputModules ] ++ [ addModules ];
    specialArgs = { inherit flakeInputs; };
  };
in {
    default = system.config.system.build.toplevel;
    system = system.config.system.build.toplevel;
    kernel = system.config.boot.kernelPackages.kernel;
    initrd = system.config.system.build.initialRamdisk;
    kernelModules = system.config.system.build.kernelModules;
}