{ config, ... }:

let cfg = config.personal.networking;
in {
  services.dhcpd4 = {
    enable = true;
    extraConfig = ''
      option subnet-mask 255.255.255.0;
      option routers ${cfg.subnets.private}.1;
      option domain-name-servers ${cfg.subnets.public}.1, 9.9.9.9;
      subnet ${cfg.subnets.private}.0 netmask 255.255.255.0 {
          range ${cfg.subnets.private}.10 ${cfg.subnets.private}.99;
      }
    '';
    interfaces = [ cfg.interfaces.wlp5ghz ];
  };

}
