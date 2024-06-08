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
      {
        # create a bridge on top of enp3s0 along with a dummy interface
        # for kea to work even when enp3s0 is disconnected
        # if you change this, you may want to change:
        # - the kea configuration in ./services/dhcp.nix
        # - the eth0 net configuration ./default.nix
        networking = {
          bridges.eth0.interfaces = ["enp3s0" "enp3s0-dummy"];
          localCommands = ''
            ip link add enp3s0-dummy type dummy
          '';
        };
        boot.kernelModules = ["dummy"];
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
