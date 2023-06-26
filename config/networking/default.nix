# https://skogsbrus.xyz/blog/2022/06/12/router/
# https://blog.fraggod.net/2017/04/27/wifi-hostapd-configuration-for-80211ac-networks.html
{ config, lib, pkgs, secrets, ... }:

let cfg = config.personal.networking;
in {
  imports = [ ./bridges.nix ./services ];

  options.personal.networking = {
    networks = lib.mkOption {
      type = with lib.types;
        attrsOf (submodule {
          options = {
            device = lib.mkOption {
              type = with lib.types; nullOr str;
              default = null;
              description = "Name of the network device.";
              example = "wlp1s0";
            };
            interface = lib.mkOption {
              type = lib.types.str;
              description = "Name of the network interface.";
              example = "enp4s0";
            };
            subnet = lib.mkOption {
              type = lib.types.str;
              description = "IPv4 subnet of the network.";
              example = "192.168.1";
            };
            machines = lib.mkOption {
              type = with lib.types;
                attrsOf (submodule {
                  options = {
                    address = lib.mkOption {
                      type = lib.types.str;
                      description = "IP address of this machine.";
                      example = "192.168.1.1";
                    };
                  };
                });
              description = "Some machines connected to this network.";
            };
          };
        });
      description = "Networks this device belongs to.";
    };
  };

  config = {
    personal.networking = {
      enable = true;
      ssh.enable = true;
      networks = {
        lan = let device = "enp4s0";
        in {
          inherit device;
          interface = device;
          subnet = "192.168.1";
          machines = {
            livebox = { address = "192.168.1.1"; };
            self = { address = "192.168.1.2"; };
          };
        };
        wan = {
          device = "wlp1s0";
          interface = "wan";
          subnet = "192.168.2";
          machines = { self.address = "192.168.2.1"; };
        };
        iot = {
          device = "wlp5s0";
          interface = "iot";
          subnet = "192.168.3";
          machines = {
            self.address = "192.168.3.1";
            sonos-move.address = "192.168.3.28";
            sonos-play1.address = "192.168.3.29";
          };
        };
        eth0 = let device = "enp3s0";
        in {
          inherit device;
          interface = device;
          subnet = "192.168.4";
          machines = { self.address = "192.168.4.1"; };
        };
      };
    };

    networking = {
      hostName = "kerberos";
      domain = "local";
      nameservers = [ cfg.networks.lan.machines.livebox.address ];

      defaultGateway = with cfg.networks.lan; {
        inherit interface;
        inherit (machines.livebox) address;
      };

      useDHCP = false;
      dhcpcd.enable = false;
      interfaces = lib.concatMapAttrs (name: value: {
        "${value.interface}" = {
          useDHCP = false;
          ipv4.addresses = lib.optional (value.machines ? self) {
            inherit (value.machines.self) address;
            prefixLength = 24;
          };
        };
      }) cfg.networks;

    };
  };
}
