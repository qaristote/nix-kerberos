{ lib, nets }:

let
  makeTable = args:
    {
      chains = { };
      flowtables = { };
      sets = { };
      maps = { };
      objects = { };
    } // args;
  makeFlowtable = args:
    {
      hook = "ingress";
      priority = "filter";
      devices = [ ];
      offload = false;
    } // args;
  makeBaseChain = type: hook:
    { priority ? type, policy ? "drop", rules ? "" }: {
      base = { inherit type hook priority policy; };
      inherit rules;
    };
  rulesCommon = {
    conntrack = ''
      ct state vmap { established : accept \
                    , related     : accept \
                    , invalid     : drop   }
    '';
    # https://en.wikipedia.org/wiki/Dynamic_Host_Configuration_Protocol#Operation
    dhcp = ''
      ip protocol udp \
        udp sport 68  \
        udp dport 67  \
        accept comment dhcp
    '';
    # https://en.wikipedia.org/wiki/Domain_Name_System#Transport_protocols
    dns = ''
      ip protocol { tcp, udp } \
        th sport 53            \
        th dport 53            \
        accept comment dns
    '';
    # https://userbase.kde.org/KDEConnect#I_have_two_devices_running_KDE_Connect_on_the_same_network,_but_they_can't_see_each_other
    kdeconnect = ''
      ip protocol { tcp, udp } \
        th dport 1714-1764     \
        accept comment kdeconnect
    '';
    ping = ''
      icmp type echo-request limit rate 5/second accept
    '';
    ssh = ''
      ip protocol tcp \
        tcp dport 22  \
        accept comment ssh
    '';
    #   # https://docs.syncthing.net/users/firewall.html
    syncthing = ''
      ip protocol tcp   \
        tcp sport 22000 \
        tcp dport 22000 \
        accept comment syncthing
      ip protocol udp   \
        udp dport 21027 \
        accept comment "syncthing: discovery broadcast"
    '';
  };
in {
  ip = {
    filter = makeTable {
      flowtables = {
        default = makeFlowtable {
          devices = lib.mapAttrsToList (_: { device, ... }: device) nets;
        };
      };
      chains = {
        wan_in.rules = with rulesCommon; dns + dhcp + ssh;
        iot_in.rules = with rulesCommon; dns + dhcp;
        input = makeBaseChain "filter" "input" {
          rules = with rulesCommon;
            conntrack + ping + ''
              meta iifname vmap { lo               : accept      \
                                , ${nets.lan.interface} : drop        \
                                , ${nets.wan.interface} : goto wan_in \
                                , ${nets.iot.interface} : goto iot_in }
            '';
        };
        forward = makeBaseChain "filter" "forward" {
          rules = with rulesCommon;
            ''
              ip protocol { udp, tcp } flow add @default
            '' + conntrack + ''
              meta oifname ${nets.lan.interface} accept
            '';
        };
      };
    };
    nat = makeTable {
      chains = {
        postrouting = makeBaseChain "nat" "postrouting" {
          priority = "srcnat";
          policy = "accept";
          rules = ''
            meta oifname ${nets.lan.interface} \
              snat to ${nets.lan.machines.self.address}
          '';
        };
      };
    };
  };

  ip6 = {
    global6 = makeTable {
      chains = {
        input = makeBaseChain "filter" "input" { };
        forward = makeBaseChain "filter" "forward" { };
      };
    };
  };

  bridge = {
    filter = makeTable {
      chains = {
        wan_wan.rules = with rulesCommon; syncthing + kdeconnect;
        forward = makeBaseChain "filter" "forward" {
          rules = with rulesCommon;
            conntrack + ''
              ether type vmap { ip6 : drop, arp : accept }
            '' + ping + ''
              meta ibrname . meta obrname vmap \
                { ${nets.wan.interface} . ${nets.wan.interface} : goto wan_wan }
            '';
        };
      };
    };
  };
}

# chain sonos_app {
#   # https://support.sonos.com/en-us/article/configure-your-firewall-to-work-with-sonos
#   # https://en.community.sonos.com/advanced-setups-229000/changed-udp-tcp-ports-for-sonos-app-needed-after-update-to-s2-6842454
#   ip protocol tcp \
#     tcp sport { 1400, 3400, 3401, 3500 } \
#     tcp dport { 1400, 3400, 3401, 3500 } \
#     accept comment "sonos: app control"
#     ip protocol udp \
#     udp sport 1900-1901 \
#     udp dport 1900-1901 \
#     accept comment "sonos: app control"
# }
# chain sonos {
#   # https://support.sonos.com/en-us/article/configure-your-firewall-to-work-with-sonos
#   # https://en.community.sonos.com/advanced-setups-229000/changed-udp-tcp-ports-for-sonos-app-needed-after-update-to-s2-6842454
#   ip protocol tcp \
#     tcp sport 4444 \
#     tcp dport 4444 \
#     accept comment "sonos: system updates"
#     ip protocol udp \
#     udp sport 6969 \
#     udp dport 6969 \
#     accept comment "sonos: setup"
#     ip protocol udp \
#     udp sport { 32413, 32414 } \
#     udp dport { 32412, 32414 } \
#     accept comment "sonos"
# }
# chain steam {
#   # https://help.steampowered.com/en/faqs/view/2EA8-4D75-DA21-31EB
#   ip protocol { udp, tcp } \
#     th dport 27015-27050 \
#     accept comment "steam: login, download"
#     ip protocol udp \
#     udp dport 27000-27100 \
#     accept comment "steam: client: game traffic"
#     ip protocol . th sport \
#     { udp . 27031-27036, tcp . 27036 } \
#     accept comment "steam: client: remote play"
#     ip protocol udp \
#     udp dport 4380 \
#     accept comment "steam: client"
#     ip protocol tcp \
#     tcp sport 27015 \
#     accept comment "steam: servers: SRCDS Rcon port"
#     ip protocol udp \
#     udp sport 27015 \
#     accept comment "steam: servers: gameplay traffic"
#     ip protocol udp \
#     udp dport { 3478, 4379, 4380, 27014-27030 } \
#     accept comment "steam: p2p, voice chat"
# }
