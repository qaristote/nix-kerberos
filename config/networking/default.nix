# https://skogsbrus.xyz/blog/2022/06/12/router/
# https://blog.fraggod.net/2017/04/27/wifi-hostapd-configuration-for-80211ac-networks.html
{ config, lib, pkgs, secrets, ... }:

let
  cfg = config.personal.networking;
in {
  imports = [ ./nat.nix ./services ];

  options.personal.networking = {
    interfaces = lib.mkOption {
      type = with lib.types; attrsOf str;
      description = "Reusable names for network devices.";
      example = {
        eth = "enp4s0";
      };
    };
    subnets = lib.mkOption {
      type = with lib.types; attrsOf str;
      description = "Reusable names for subnets.";
      example = {
        private = "192.168.1";
      };
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
      subnets = {
        public = "192.168.1";
        private = "192.168.2";
      };
    };

    networking = {
      hostName = "kerberos";
      domain = "local";

      defaultGateway = {
        address = "${cfg.subnets.public}.1";
        interface = cfg.interfaces.eth;
      };

      dhcpcd.enable = false;
      interfaces = {
        "${cfg.interfaces.eth}" = {
          useDHCP = false;
          ipv4.addresses = [{
            address = "${cfg.subnets.public}.2";
            prefixLength = 24;
          }];
        };
        "${cfg.interfaces.wlp5ghz}" = {
          useDHCP = false;
          ipv4.addresses = [{
            address = "${cfg.subnets.private}.1";
            prefixLength = 24;
          }];
        };
      };
    };
  };
}
