{ config, ... }:

let cfg = config.personal.networking;
in {
  services.dhcpd4 = {
    enable = true;
    interfaces = with cfg.interfaces; [ wlp2ghz wlp5ghz ];
    extraConfig = with cfg.subnets; ''
      option domain-name-servers ${public}.1, 9.9.9.9;
      subnet ${private}.0 netmask 255.255.255.0 {
          option broadcast-address ${private}.255;
          option routers ${private}.1;
          option subnet-mask 255.255.255.0;
          interface ${cfg.interfaces.wlp5ghz};
          range ${private}.10 ${private}.99;
      }
      subnet ${iot}.0 netmask 255.255.255.0 {
          option broadcast-address ${iot}.255;
          option routers ${iot}.1;
          option subnet-mask 255.255.255.0;
          interface ${cfg.interfaces.wlp2ghz};
          range ${iot}.10 ${iot}.99
      }
    '';
  };
}
