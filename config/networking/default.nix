# https://skogsbrus.xyz/blog/2022/06/12/router/
# https://blog.fraggod.net/2017/04/27/wifi-hostapd-configuration-for-80211ac-networks.html
{ config, lib, pkgs, secrets, ... }:

let cfg = config.personal.networking;
in {
  imports = [ ./nat.nix ./services ];

  options.personal.networking = {
    interfaces = lib.mkOption {
      type = with lib.types;
        attrsOf (submodule {
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
                address = lib.mkOption {
                  type = lib.types.str;
                  description = "IP address of this machine.";
                  example = "192.168.1.1";
                };
              });
            description = "Some machines connected to this network.";
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
        lan = {
          interface = "enp4s0";
          subnet = "192.168.1";
          machines = {
            livebox = { address = "192.168.1.1"; };
            self = { address = "192.168.1.2"; };
          };
        };
        wan = {
          interface = "wlp1s0";
          subnet = "192.168.2";
          machines = { self.address = "192.168.2.1"; };
        };
        iot = {
          interface = "wlp5s0";
          subnet = "192.168.3";
          machines = { self.address = "192.168.3.1"; };
        };
      };
    };

    networking = {
      hostName = "kerberos";
      domain = "local";

      defaultGateway = with cfg.networks.lan; {
        inherit interface;
        inherit (machines.livebox) address;
      };

      dhcpcd.enable = false;
      interfaces = lib.concatMapAttrs (name: value: {
        "${value.interface}" = {
          useDHCP = false;
          ipv4.address = lib.optional (value.machines ? self) {
            inherit (value.machines) address;
            prefixLength = 24;
          };
        };
      }) cfg.networks;
    };
  };
}
