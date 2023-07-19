{ config, pkgs, ... }:

let
  nets = config.personal.networking.networks;
  nets-dependencies =
    builtins.map (subnet: "${subnet.interface}-netdev.service")
    (with nets; [ wan iot ]);
  conf = pkgs.writeText "igmpproxy.conf" ''
    phyint ${nets.wan.interface} upstream
     ratelimit 0 threshold 1 phyint ${nets.iot.interface} downstream ratelimit 0
     threshold 1 phyint ${nets.lan.interface} downstream ratelimit 0 threshold 1
  '';
in {
  systemd.services.igmpproxy = {
    description = "Multicast router utilizing IGMP forwarding";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ] ++ nets-dependencies;
    requires = nets-dependencies;
    path = [ pkgs.igmpproxy ];
    script = "igmpproxy -v -n ${conf}";
  };
}
