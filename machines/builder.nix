system-type:
addModules: 
{
  inputModules, 
  nixpkgs
}: 
let 
  system = nixpkgs.lib.nixosSystem {
    system = system-type;
    modules = if builtins.isList inputModules then inputModules ++ addModules else [ inputModules ] ++ [ addModules];
    # modules = if builtins.isList addModules then listModules ++ addModules else listModules ++ [ addModules ]; 
  };
in {
    default = system.config.system.build.toplevel;
    system = system.config.system.build.toplevel;
    kernel = system.config.boot.kernelPackages.kernel;
    initrd = system.config.system.build.initialRamdisk;
    kernelModules = system.config.system.build.kernelModules;
}