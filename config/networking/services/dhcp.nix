{
  config,
  lib,
  ...
}: let
  ifaces = config.personal.networking.interfaces;
  dependencies =
    builtins.concatMap (iface: ["${iface}-netdev.service" "network-addresses-${iface}.service"])
    ["wan" "iot" "guest"]; # not enp3s0 because it may come down for good reasons
in {
  services.kea.dhcp4 = {
    enable = true;
    settings = let
      subnets = with ifaces; lib.filterAttrs (_: builtins.hasAttr "subnet") ifaces.all;
    in {
      interfaces-config = {
        interfaces = builtins.attrNames subnets;
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
          data = lib.concatStringsSep ", " config.networking.nameservers;
        }
        {
          name = "subnet-mask";
          data = "255.255.255.0";
        }
      ];
      subnet4 =
        lib.mapAttrsToList (interface: {
          subnet,
          machines,
          ...
        }: {
          subnet = "${subnet.prefix}.0/${builtins.toString subnet.prefixLength}";
          id = lib.toInt (lib.removePrefix "192.168." subnet.prefix);
          option-data = [
            {
              name = "broadcast-address";
              data = "${subnet.prefix}.255";
            }
            {
              name = "routers";
              data = machines.self.ip;
            }
          ];
          inherit interface;
          pools = [{pool = "${subnet.prefix}.10 - ${subnet.prefix}.99";}];
          reservations =
            lib.mapAttrsToList (_: {
              ip,
              mac,
            }: {
              hw-address = mac;
              ip-address = ip;
            })
            (lib.filterAttrs (name: addresses: name != "self" && addresses ? mac && addresses ? ip) machines);
        })
        subnets;
    };
  };

  systemd.services.kea-dhcp4-server = {
    after = dependencies;
    bindsTo = dependencies;
  };
}
