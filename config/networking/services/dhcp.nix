{ config, ... }:

let
  makeSubnet = network: ''
    subnet ${network.subnet}.0 netmask 255.255.255.0 {
      option broadcast-address ${network.subnet}.255;
      option routers ${network.machines.self.address};
      interface ${network.interface};
      range ${network.subnet}.10 ${network.subnet}.99
    }
  '';
in {
  services.dhcpd4 = with config.personal.networking.networks; {
    enable = true;
    interfaces = [ wan.interface iot.interface ];
    extraConfig = ''
      option domain-name-servers ${lan.subnet}.1, 9.9.9.9;
      option subnet-mask 255.255.255.0;
    '' + makeSubnet wan + makeSubnet iot;
  };
}
