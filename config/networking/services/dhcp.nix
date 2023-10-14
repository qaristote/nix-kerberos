{ config, ... }:

let
  nets = config.personal.networking.networks;
  netdevServices = builtins.map (subnet: "${subnet.interface}-netdev.service")
    (with nets; [ wan iot ]);
in {
  services.kea.dhcp4 = {
    enable = true;
    settings = let subnets = with nets; [ wan iot eth0 ];
    in {
      interfaces-config = {
        interfaces = builtins.map (network: network.interface) subnets;
        service-sockets-max-retries = 20;
        service-sockets-retry-wait-time = 5000;
      };
      lease-database = {
        name = "/var/lib/kea/dhcp4.leases";
        persist = true;
        type = "memfile";
      };
      valid-lifetime = 600;
      max-valid-lifetime = 7200;
      option-data = [
        {
          name = "domain-name-servers";
          data = "${nets.lan.subnet}.1, 9.9.9.9";
        }
        {
          name = "subnet-mask";
          data = "255.255.255.0";
        }
      ];
      subnet4 = builtins.map (network: {
        subnet = "${network.subnet}.0/24";
        option-data = [
          {
            name = "broadcast-address";
            data = "${network.subnet}.255";
          }
          {
            name = "routers";
            data = network.machines.self.address;
          }
        ];
        inherit (network) interface;
        pools = [{ pool = "${network.subnet}.10 - ${network.subnet}.99"; }];
      }) subnets;
    };
  };

  systemd.services.kea-dhcp4-server.after = netdevServices;
  systemd.services.kea-dhcp4-server.bindsTo = netdevServices;
}
