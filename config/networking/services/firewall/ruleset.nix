{interfaces, ...}: let
  machines = {
    inherit
      (interfaces.all.iot.machines)
      sonos-play1
      sonos-move
      ;
  };
  makeTable = args:
    {
      chains = {};
      flowtables = {};
      sets = {};
      maps = {};
      objects = {};
    }
    // args;
  makeFlowtable = args:
    {
      hook = "ingress";
      priority = "filter";
      devices = [];
      offload = false;
    }
    // args;
  makeBaseChain = type: hook: {
    priority ? type,
    policy ? "drop",
    rules ? "",
  }: {
    base = {inherit type hook priority policy;};
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
    igmp = ''
      ip protocol igmp accept comment "igmp"
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
    # https://www.packetmischief.ca/2021/08/04/operating-sonos-speakers-in-a-multi-vlan-network/
    ssdp = ''
      ip protocol udp \
        ip daddr { 239.255.255.250, 255.255.255.255 } \
        udp dport 1900 \
        accept comment ssdp
    '';
    ssh = ''
      ip protocol tcp \
        tcp dport 22  \
        accept comment ssh
    '';
    # https://support.sonos.com/en-us/article/configure-your-firewall-to-work-with-sonos
    # https://en.community.sonos.com/advanced-setups-229000/changed-udp-tcp-ports-for-sonos-app-needed-after-update-to-s2-6842454
    sonos = {
      controller-player = ''
        ip protocol tcp \
          tcp dport { 1400, 1443, 4444 } \
          accept comment "sonos: app control: system update"
      '';
      player-controller = ''
        ip protocol udp \
          ip saddr { ${machines.sonos-move.ip}  \
                   , ${machines.sonos-play1.ip} } \
          udp sport >30000 \
          udp dport >30000 \
          accept comment "sonos: app control: player to controller"
        ip protocol tcp \
          ip saddr { ${machines.sonos-move.ip}  \
                   , ${machines.sonos-play1.ip} } \
          tcp dport { 3400, 3401, 3500 } \
          accept comment "sonos: app control: player to controller"
      '';
    };
    # https://docs.syncthing.net/users/firewall.html
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
          devices = builtins.attrNames interfaces.devices;
        };
      };
      chains = {
        wan_in.rules = with rulesCommon; dns + dhcp + ssh + ssdp;
        iot_in.rules = with rulesCommon; dns + dhcp + igmp;
        guest_in.rules = with rulesCommon; dns + dhcp;
        enp3s0_in.rules = with rulesCommon; dns + dhcp;
        input = makeBaseChain "filter" "input" {
          rules = with rulesCommon;
            conntrack
            + ping
            + ''
              meta iifname vmap { lo     : accept         \
                                , wan    : goto wan_in    \
                                , iot    : goto iot_in    \
                                , guest  : goto guest_in  \
                                , enp3s0 : goto enp3s0_in }
            '';
        };
        iot_wan.rules = rulesCommon.sonos.player-controller;
        wan_iot.rules = with rulesCommon; sonos.controller-player + ssdp;
        wan_enp3s0.rules = rulesCommon.kdeconnect;
        enp3s0_wan.rules = rulesCommon.kdeconnect;
        forward = makeBaseChain "filter" "forward" {
          rules = with rulesCommon;
            ''
              ip protocol { udp, tcp } flow add @default
            ''
            + conntrack
            + ''
              meta oifname enp4s0 accept
              meta iifname . meta oifname vmap   \
                { wan . iot    : goto wan_iot    \
                , iot . wan    : goto iot_wan    \
                , wan . enp3s0 : goto wan_enp3s0 \
                , enp3s0 . wan : goto enp3s0_wan }
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
            meta oifname enp4s0 \
              snat to ${interfaces.all.enp4s0.machines.self.ip}
          '';
        };
      };
    };
  };

  ip6 = {
    global6 = makeTable {
      chains = {
        input = makeBaseChain "filter" "input" {};
        forward = makeBaseChain "filter" "forward" {};
      };
    };
  };

  bridge = {
    filter = makeTable {
      chains = {
        iot_iot.rules = with rulesCommon;
          ''
            ip saddr { ${machines.sonos-move.ip}  \
                     , ${machines.sonos-play1.ip} } \
            ip daddr { ${machines.sonos-move.ip}  \
                     , ${machines.sonos-play1.ip} } \
              accept comment "sonos: player to player"
          ''
          + ssdp
          + sonos.player-controller
          + sonos.controller-player;
        wan_wan.rules = with rulesCommon; syncthing + kdeconnect;
        forward = makeBaseChain "filter" "forward" {
          rules = with rulesCommon;
            conntrack
            + ''
              ether type vmap { ip6 : drop, arp : accept }
            ''
            + ping
            + ''
              meta ibrname . meta obrname vmap \
                { wan . wan : goto wan_wan \
                , iot . iot : goto iot_iot }
            '';
        };
      };
    };
  };
}
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

