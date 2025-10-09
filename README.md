# Somana Nixpkgs

This is the software package management for all top-level Somana software and machine definitions. 



### Building Raspberry Pi
The RPi closure is built from an arm machine using 

`nix build .#machines.rpi-base` 

The structure of references is 

#### flake.nix: 
Defines the top-level machine defitions by using the `arm-builder` function. This function is defined in the `let` section, which defines variables and functions for use in the output portion. For more information on this, take a look through [nix pills](https://nixos.org/guides/nix-pills/). 

#### builder.nix: 
Defines the function for compiling packages. This uses the standard `nixpkgs.lib.nixosSystem` to build multiple packages, including the machine closure (`toplevel`) as well as the kernel. 

#### rpi.nix
This is the machine definition. It is currently laid out to contain all of the definitions required, including system packages, services, logins, and networking. This should be broken out into multiple files when we determine what the structure of the robots will be. 


### Deploying the RPi Build

Once you complete the build process, you will be left with a `result` directory with a symlink to the nix store. This is the closure that we will deploy. To deploy, run

`nix copy --to ssh://<login>@<ip> ./result`

This will copy the pacakge over. Once it is on the device, we will need to activate it. Find the symlinked package and on the RPi run

`/nix/store/<path>/bin/activate`

The package will then be activated, but may require a reboot. Follow any steps that the activate script dumps out. 