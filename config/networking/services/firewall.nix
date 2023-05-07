{ config, lib, ... }:

let nets = config.personal.networking.networks;
in {
  boot.kernel.sysctl = { "net.ipv4.conf.all.forwarding" = true; };

  networking = {
    nftables = {
      enable = true;
      ruleset = with nets; ''
        table ip filter {
          chain conntrack {
            ct state vmap { established : accept \
                          , related     : accept \
                          , invalid     : drop   }
          }
          chain dhcp {
            # https://en.wikipedia.org/wiki/Dynamic_Host_Configuration_Protocol#Operation
            ip protocol udp \
              udp sport 68 \
              udp dport 67 \
              accept comment "dhcp"
          }
          chain dns {
            # https://en.wikipedia.org/wiki/Domain_Name_System#Transport_protocols
            ip protocol { tcp, udp } \
              th sport 53 \
              th dport 53 \
              accept comment "dns"
          }
          chain kdeconnect {
            # https://userbase.kde.org/KDEConnect#I_have_two_devices_running_KDE_Connect_on_the_same_network,_but_they_can't_see_each_other
            ip protocol { tcp, udp } \
              th sport 1714-1764 \
              th dport 1714-1764 \
              accept comment "kdeconnect"
          }
          chain sonos_app {
            # https://support.sonos.com/en-us/article/configure-your-firewall-to-work-with-sonos
            # https://en.community.sonos.com/advanced-setups-229000/changed-udp-tcp-ports-for-sonos-app-needed-after-update-to-s2-6842454
            ip protocol tcp \
              tcp sport { 1400, 3400, 3401, 3500 } \
              tcp dport { 1400, 3400, 3401, 3500 } \
              accept comment "sonos: app control"
            ip protocol udp \
              udp sport 1900-1901 \
              udp dport 1900-1901 \
              accept comment "sonos: app control"
          }
          chain sonos {
            # https://support.sonos.com/en-us/article/configure-your-firewall-to-work-with-sonos
            # https://en.community.sonos.com/advanced-setups-229000/changed-udp-tcp-ports-for-sonos-app-needed-after-update-to-s2-6842454
            ip protocol tcp \
              tcp sport 4444 \
              tcp dport 4444 \
              accept comment "sonos: system updates"
            ip protocol udp \
              udp sport 6969 \
              udp dport 6969 \
              accept comment "sonos: setup"
            ip protocol udp \
              udp sport { 32413, 32414 } \
              udp dport { 32412, 32414 } \
              accept comment "sonos"
          }
          chain ssh {
            ip protocol tcp \
              tcp dport 22 \
              accept comment "ssh"
          }
          chain steam {
            # https://help.steampowered.com/en/faqs/view/2EA8-4D75-DA21-31EB
            ip protocol { udp, tcp } \
              th dport 27015-27050 \
              accept comment "steam: login, download"
            ip protocol udp \
              udp dport 27000-27100 \
              accept comment "steam: client: game traffic"
            ip protocol . th sport \
              { udp . 27031-27036, tcp . 27036 } \
              accept comment "steam: client: remote play"
            ip protocol udp \
              udp dport 4380 \
              accept comment "steam: client"
            ip protocol tcp \
              tcp sport 27015 \
              accept comment "steam: servers: SRCDS Rcon port"
            ip protocol udp \
              udp sport 27015 \
              accept comment "steam: servers: gameplay traffic"
            ip protocol udp \
              udp dport { 3478, 4379, 4380, 27014-27030 } \
              accept comment "steam: p2p, voice chat"
          }
          chain syncthing {
            # https://docs.syncthing.net/users/firewall.html
            ip protocol { tcp, udp } \
              th sport 22000 \
              th dport 22000 \
              accept comment "syncthing"
            ip protocol udp \
              udp sport 21027 \
              udp dport 21027 \
              accept comment "syncthing: discovery broadcasts"
          }

          chain in_wan {
            jump dns
            jump dhcp
            jump ssh
          }
          chain in_iot {
            jump dns
            jump dhcp
          }
          chain inbound {
            type filter hook input priority 0; policy drop;
            icmp type echo-request limit rate 5/second accept
            jump conntrack
            meta iifname vmap \
              { lo               : accept                      \
              , ${lan.interface} : drop                        \
              , ${wan.interface} : goto in_wan \
              , ${iot.interface} : goto in_iot }
          }

          chain wan_wan {
            jump kdeconnect
            jump syncthing
          }
          chain iot_wan {
            jump sonos_app
          }
          chain forward {
            type filter hook forward priority 0; policy drop;
            jump conntrack
            meta oifname ${lan.interface} accept
            meta iifname ${wan.interface} meta oifname ${wan.interface} \
              goto wan_wan
            meta iifname ${iot.interface} meta oifname ${wan.interface} \
              goto iot_wan
          }
        }

        table ip nat {
          chain postrouting {
            type nat hook postrouting priority 100; policy accept;
            meta oifname ${lan.interface} snat to ${lan.machines.self.address}
          }
        }

        table ip6 global6 {
         chain input {
            type filter hook input priority 0; policy drop;
          }
          chain forward {
            type filter hook forward priority 0; policy drop;
          }
        }
      '';
    };

    firewall.enable = lib.mkForce false;
  };
}
