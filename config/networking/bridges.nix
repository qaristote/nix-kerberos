{
  config,
  lib,
  pkgs,
  ...
}: let
  bridges = config.personal.networking.interfaces.bridges;
in {
  config = {
    networking.bridges = lib.mapAttrs (_: _: {interfaces = [];}) bridges;
    systemd.services = lib.mkMerge ([
        {
          hostapd.postStart = lib.mkBefore ''
            sleep 10
          '';
        }
      ]
      ++ (lib.mapAttrsToList (bridge: {interfaces, ...}: {
          "${bridge}-netdev".script = ''
            echo Setting forward delay to 0 for ${bridge}...
            ip link set ${bridge} type bridge forward_delay 0
          '';

          hostapd.postStart =
            lib.concatMapStringsSep "\n" (interface: ''
              echo Setting ${interface} to hairpin mode...
              ${pkgs.iproute2}/bin/bridge link set dev ${interface} hairpin on
            '')
            interfaces;
        })
        bridges));
  };
}
