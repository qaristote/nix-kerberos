{
  nixos-hardware,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/profiles/headless.nix")
    ./hardware-configuration.nix
    nixos-hardware.nixosModules.pcengines-apu
    nixos-hardware.nixosModules.common-pc-ssd
    nixos-hardware.nixosModules.common-cpu-amd
  ];

  personal.hardware = {
    usb.enable = true;
    firmwareNonFree.enable = true;
    disks.crypted = "/dev/disk/by-uuid/47e77d74-1aad-4d99-9aa7-568d8524b305";
  };

  swapDevices = [{device = "/swap";}];

  # The CPU frequency should stay at the minimum until the router has
  # some load to compute.
  powerManagement.cpuFreqGovernor = "ondemand";
  services.acpid.enable = true;

  # The service irqbalance is useful as it assigns certain IRQ calls
  # to specific CPUs instead of letting the first CPU core to handle
  # everything. This is supposed to increase performance by hitting
  # CPU cache more often.
  services.irqbalance.enable = true;

  # Re-enable the serial console, disabled by the headless profile
  systemd.services."serial-getty@ttyS0".enable = true;
}
