{
  lib,
  pkgs,
  ...
}: let
  upstream = "wan";
  downstream = ["iot"];
  netdevServices = builtins.map (iface: "${iface}-netdev.service") ([upstream] ++ downstream);
  conf = pkgs.writeText "igmpproxy.conf" (''
      phyint ${upstream} upstream ratelimit 0 threshold 1
    ''
    + lib.concatMapStrings (iface: ''
      phyint ${iface} downstream ratelimit 0 threshold 1
    '')
    downstream);
in {
  systemd.services.igmpproxy = {
    description = "Multicast router utilizing IGMP forwarding";
    wantedBy = ["multi-user.target"];
    after = ["kea-dhcp4-server.service"] ++ netdevServices;
    bindsTo = netdevServices;
    path = [pkgs.igmpproxy];
    script = "igmpproxy -v -n ${conf}";
  };
}
