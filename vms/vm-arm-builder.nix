{ self, nixpkgs, pkgs }:
  let
    pkgsAarch64 = import nixpkgs { system = "aarch64-linux"; };

    iso = (pkgsAarch64.nixos {
      imports = [ "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-base.nix" ];
    }).config.system.build.isoImage;

in 
   pkgs.writeScriptBin {
    name = "run-vm"; 
    text = ''
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
   }