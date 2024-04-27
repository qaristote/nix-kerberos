{ config, pkgs, ... }:

let
  nets = config.personal.networking.networks;
  netdevServices = builtins.map (subnet: "${subnet.interface}-netdev.service")
    (with nets; [ wan iot ]);
  conf = pkgs.writeText "igmpproxy.conf" ''
    phyint ${nets.wan.interface} upstream ratelimit 0 threshold 1
    phyint ${nets.iot.interface} downstream ratelimit 0 threshold 1
  '';
in {
  systemd.services.igmpproxy = {
    description = "Multicast router utilizing IGMP forwarding";
    wantedBy = [ "multi-user.target" ];
    after = [ "kea-dhcp4-server.service" ] ++ netdevServices;
    bindsTo = netdevServices;
    path = [ pkgs.igmpproxy ];
    script = "igmpproxy -v -n ${conf}";
  };
}
