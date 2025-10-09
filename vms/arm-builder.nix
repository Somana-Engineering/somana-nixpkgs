{ pkgs, nixpkgs }: 
let 
    pkgsAarch64 = import nixpkgs {system = "aarch64-linux"; };

    vmScript = pkgs.writeScriptBin "launch-arm-builder" ''
      #!${pkgs.runtimeShell}
      ${pkgs.qemu}/bin/qemu-system-aarch64 \
        -machine virt,gic-version=max \
        -cpu max \
        -m 2G \
        -smp 4 \
        -drive file=/home/nixos/Downloads/ubuntu-24.04.3-live-server-arm64.iso,format=raw,readonly=on \
        -nographic \
        -bios ${pkgsAarch64.OVMF.fd}/FV/QEMU_EFI.fd
    '';
  in {
    defaultPackage.x86_64-linux = vmScript;
  } 
