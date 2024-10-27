{
  config,
  lib,
  ...
}: let
  ifaces = config.personal.networking.interfaces;
in {
  imports = [./bridges.nix ./services];

  options.personal.networking = {
    interfaces = lib.mkOption {
      type = with lib.types; attrsOf anything;
      description = "Available interfaces.";
    };
  };

  config = {
    personal.networking = {
      enable = true;
      ssh.enable = true;
      interfaces = let
        devices = {
          enp2s0.machines.self.mac = "00:0d:b9:5f:58:f0";
          enp3s0 = {
            subnet = {
              prefix = "192.168.4";
              prefixLength = 24;
            };
            machines = {
              self = {
                mac = "00:0d:b9:5f:58:f1";
                ip = "192.168.4.1";
              };
              steam-deck = {
                mac = "10:82:86:22:90:17";
                ip = "192.168.4.10";
              };
            };
          };
          enp4s0 = {
            subnet = {
              prefix = "192.168.1";
              prefixLength = 24;
            };
            machines = {
              self = {
                mac = "00:0d:b9:5f:58:f2";
                ip = "192.168.1.2";
              };
              livebox.ip = "192.168.1.1";
            };
          };
          wlp1s0 = {
            bridges = ["wan"];
            machines.self.mac = "04:f0:21:b6:11:fc";
          };
          wlp5s0 = {
            bridges = ["wan"];
            machines.self.mac = "04:f0:21:b2:61:09";
          };
        };
        wlan = {
          wlp1s0-iot = {
            device = "wlp1s0";
            machines.self.mac = "02:f0:21:b6:11:fc";
            bridges = ["iot"];
          };
          wlp5s0-iot = {
            device = "wlp5s0";
            machines.self.mac = "02:f0:21:b2:61:09";
            bridges = ["iot"];
          };
          wlp5s0-guest = {
            device = "wlp5s0";
            machines.self.mac = "06:f0:21:b2:61:09";
            bridges = ["guest"];
          };
        };
        bridges = {
          wan = {
            interfaces = ["wlp1s0" "wlp5s0"];
            subnet = {
              prefix = "192.168.2";
              prefixLength = 24;
            };
            machines.self.ip = "192.168.2.1";
          };
          iot = {
            interfaces = ["wlp1s0-iot" "wlp5s0-iot"];
            subnet = {
              prefix = "192.168.3";
              prefixLength = 24;
            };
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
          guest = {
            interfaces = ["wlp5s0-guest"];
            subnet = {
              prefix = "192.168.5";
              prefixLength = 24;
            };
            machines.self.ip = "192.168.5.1";
          };
        };
      in {
        inherit devices wlan bridges;
        all = devices // wlan // bridges;
      };
    };

    networking = {
      hostName = "kerberos";
      domain = "local";

      nameservers = [
        # quad9
        "9.9.9.9"
        "149.112.112.112"
        # isp
        config.networking.defaultGateway.address
      ];
      defaultGateway = let
        interface = "enp4s0";
      in {
        inherit interface;
        address = ifaces.all."${interface}".machines.livebox.ip;
      };

      useDHCP = false;
      dhcpcd.enable = false;

      interfaces =
        lib.concatMapAttrs (interface: attrs: {
          "${interface}" = {
            ipv4.addresses = lib.optional (attrs ? machines.self.ip) {
              address = attrs.machines.self.ip;
              prefixLength = 24;
            };
          };
        })
        ifaces.all;
    };
  };
}
