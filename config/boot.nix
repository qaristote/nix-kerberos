{ pkgs, ... }:

{
  personal.boot = {
    grub.enable = true;
  };
  boot.loader.grub.device = "/dev/disk/by-id/ata-SATA_SSD_A45E07221AE300053322";
  # This makes the system use the XanMod Linux kernel,  a set of
  # patches reducing latency and improving performance. 
  boot.kernelPackages = pkgs.linuxPackages_xanmod_latest;
}
