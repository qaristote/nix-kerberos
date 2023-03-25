{ config, pkgs, ... }:

let nets = config.personal.networking.networks;
    conf = pkgs.writeText "igmpproxy.conf" ''
      phyint ${nets.wan.interface} upstream   ratelimit 0 threshold 1
      phyint ${nets.iot.interface} downstream ratelimit 0 threshold 1
      phyint ${nets.lan.interface} downstream ratelimit 0 threshold 1
    '';
in {
  systemd.services.igmpproxy = {
    description = "Multicast router utilizing IGMP forwarding";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    path = [ pkgs.igmpproxy ];
    script = "igmpproxy -vv -n ${conf}";
  };
}
