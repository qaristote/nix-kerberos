{ ... }:
{
  personal.boot = {
    grub.enable = true;
  };
  boot.loader.grub.device = "/dev/disk/by-id/ata-SATA_SSD_A45E07221AE300053322";
}
