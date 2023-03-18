{ nixos-hardware, ... }: {
  imports = [
    ./hardware-configuration.nix
    nixos-hardware.nixosModules.pcengines-apu
    nixos-hardware.nixosModules.common-pc-ssd
    nixos-hardware.nixosModules.common-cpu-amd
  ];
  personal.hardware = {
    usb.enable = true;
    firmwareNonFree.enable = true;
  };
  swapDevices = [{ device = "/swap"; }];
}
