{
  arch,
  inputModules, 
  nixpkgs
}: 
let 
  system = nixpkgs.lib.nixosSystem {
    system = "aarch64-linux";
    modules = if builtins.isList inputModules then inputModules else [ inputModules ];
  };
in {
    default = system.config.system.build.toplevel;
    system = system.config.system.build.toplevel;
    kernel = system.config.boot.kernelPackages.kernel;
    initrd = system.config.system.build.initialRamdisk;
    kernelModules = system.config.system.build.kernelModules;
}