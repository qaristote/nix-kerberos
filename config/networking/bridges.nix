{
  config,
  lib,
  pkgs,
  ...
}: let
  nets = config.personal.networking.networks;
in {
  config = lib.mkMerge ([
      {
        systemd.services.hostapd.postStart = lib.mkForce (lib.mkBefore ''
          sleep 3
        '');
      }
    ]
    ++ (builtins.map (network: let
      bridge = network.interface;
      device = network.device;
    in {
      networking.bridges."${bridge}".interfaces = [];

      systemd.services."${bridge}-netdev".script = ''
        echo Setting forward delay to 0 for ${bridge}...
        ip link set ${bridge} type bridge forward_delay 0
      '';

      systemd.services.hostapd.postStart = lib.mkForce ''
        echo Setting ${device} to hairpin mode...
        ${pkgs.iproute2}/bin/bridge link set dev ${device} hairpin on
      '';
    }) [nets.wan nets.iot]));
}
