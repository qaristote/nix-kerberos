# https://skogsbrus.xyz/blog/2022/06/12/router/
# https://blog.fraggod.net/2017/04/27/wifi-hostapd-configuration-for-80211ac-networks.html
{ config, lib, pkgs, secrets, ... }:

let
  ifaces = config.personal.networking.interfaces;
  publicSubnet = "192.168.1";
  privateSubnet = "192.168.2";
in {
  imports = [ ./hostapd.nix ];

  options.personal.networking = {
    interfaces = let
      makeInterfaceOption = type:
        lib.mkOption {
          type = lib.types.str;
          description = "Network device for the ${type} interface.";
          example = "enp4s0";
        };
    in {
      eth = makeInterfaceOption "ethernet";
      wlp2ghz = makeInterfaceOption "2 GHz WiFi";
      wlp5ghz = makeInterfaceOption "5 GHz WiFi";
    };
  };

  config = {
    personal.networking = {
      enable = true;
      ssh.enable = true;
      interfaces = {
        eth = "enp4s0";
        wlp2ghz = "wlp5s0";
        wlp5ghz = "wlp1s0";
      };
    };

    networking = {
      hostName = "kerberos";
      domain = "local";

      defaultGateway = {
        address = "${publicSubnet}.1";
        interface = ifaces.eth;
      };

      dhcpcd.enable = false;
      interfaces = {
        "${ifaces.eth}" = {
          ipv4.addresses = [{
            address = "${publicSubnet}.2";
            prefixLength = 24;
          }];
        };
        "${ifaces.wlp5ghz}" = {
          ipv4.addresses = [{
            address = "${privateSubnet}.1";
            prefixLength = 24;
          }];
        };
      };

      nat = {
        enable = true;
        externalInterface = ifaces.eth;
        internalInterfaces = [
          # ifaces.wlp2ghz
          ifaces.wlp5ghz
        ];
      };

      firewall.interfaces."${ifaces.wlp5ghz}" = {
        allowedTCPPorts = [ 53 ];
        allowedUDPPorts = [ 53 ];
      };
    };

    services.dhcpd4 = {
      enable = true;
      extraConfig = ''
        option subnet-mask 255.255.255.0;
        option routers ${privateSubnet}.1;
        option domain-name-servers ${privateSubnet}.1, 9.9.9.9;
        subnet ${privateSubnet}.0 netmask 255.255.255.0 {
            range ${privateSubnet}.10 ${privateSubnet}.99;
        }
      '';
      interfaces = [ ifaces.wlp5ghz ];
    };

    services.unbound = {
      enable = true;
      settings = {
        server = {
          interface = [ "127.0.0.1" "${privateSubnet}.1" ];
          access-control = [
            "0.0.0.0/0 refuse"
            "127.0.0.0/8 allow"
            "${privateSubnet}.0/24 allow"
          ];
        };
      };
    };
  };
}
