{ config, lib, utils, pkgs, ... }:

let nets = config.personal.networking.networks;
in {
  config = lib.mkMerge ((builtins.map (network:
    let
      bridge = network.interface;
      device = network.device;
    in {
      networking.bridges."${bridge}".interfaces = [ ];

      systemd.services."${bridge}-netdev".script = ''
        echo Setting forward delay to 0 for ${bridge}...
        ip link set ${bridge} type bridge forward_delay 0
      '';

      systemd.services.hostapd.postStart = ''
        sleep 3
        ${pkgs.iproute2}/bin/bridge link set dev ${device} hairpin on
      '';
    }) [ nets.wan nets.iot ]) ++ [{
      networking.bridges.${nets.wan.interface}.interfaces = [ "enp3s0" ];
    }]);
}
