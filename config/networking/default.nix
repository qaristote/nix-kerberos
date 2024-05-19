# https://skogsbrus.xyz/blog/2022/06/12/router/
# https://blog.fraggod.net/2017/04/27/wifi-hostapd-configuration-for-80211ac-networks.html
{
  config,
  lib,
  ...
}: let
  cfg = config.personal.networking;
in {
  imports = [./bridges.nix ./services];

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
                    ip = lib.mkOption {
                      type = lib.types.str;
                      description = "IP address of this machine.";
                      example = "192.168.1.1";
                    };
                    mac = lib.mkOption {
                      type = with lib.types; nullOr str;
                      description = "MAC address of this machine.";
                      default = null;
                      example = "01:23:45:67:89:ab";
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
        lan = let
          device = "enp4s0";
        in {
          inherit device;
          interface = device;
          subnet = "192.168.1";
          machines = {
            livebox = {ip = "192.168.1.1";};
            self = {ip = "192.168.1.2";};
          };
        };
        wan = {
          device = "wlp1s0";
          interface = "wan";
          subnet = "192.168.2";
          machines = {self.ip = "192.168.2.1";};
        };
        iot = {
          device = "wlp5s0";
          interface = "iot";
          subnet = "192.168.3";
          machines = {
            self.ip = "192.168.3.1";
            sonos-move = {
              ip = "192.168.3.10";
              mac = "54:2a:1b:73:7a:1e";
            };
            sonos-play1 = {
              ip = "192.168.3.11";
              mac = "5c:aa:fd:44:b2:6a";
            };
          };
        };
        eth0 = let
          device = "enp3s0";
        in {
          inherit device;
          interface = device;
          subnet = "192.168.4";
          machines = {
            self.ip = "192.168.4.1";
            steam-deck = {
              ip = "192.168.4.10";
              mac = "10:82:86:22:90:17";
            };
          };
        };
      };
    };

    networking = {
      hostName = "kerberos";
      domain = "local";
      nameservers = [cfg.networks.lan.machines.livebox.ip];

      defaultGateway = with cfg.networks.lan; {
        inherit interface;
        address = machines.livebox.ip;
      };

      useDHCP = false;
      dhcpcd.enable = false;
      interfaces =
        lib.concatMapAttrs (_: {
          interface,
          machines,
          ...
        }: {
          "${interface}" = {
            useDHCP = false;
            ipv4.addresses = lib.optional (machines ? self) {
              address = machines.self.ip;
              prefixLength = 24;
            };
          };
        })
        cfg.networks;
    };
  };
}
