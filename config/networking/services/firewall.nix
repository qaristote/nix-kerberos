{ config, ... }:

let nets = config.personal.networking.networks;
in {
  boot.kernel.sysctl = { "net.ipv4.conf.all.forwarding" = true; };

  networking = {
    nftables = {
      enable = true;
      ruleset = with nets; ''
        table ip global {
          chain inbound_lan {
            icmp type echo-request limit rate 5/second accept
          }
          chain inbound_wan {
            icmp type echo-request limit rate 5/second accept
            ip protocol . th dport { tcp . 22 \
                                   , udp . 53 \
                                   , tcp . 53 \
                                   , udp . 67 } accept
          }
          chain inbound_iot {
            icmp type echo-request limit rate 5/second accept
            ip protocol . th dport { udp . 53 \
                                   , tcp . 53 \
                                   , udp . 67 } accept
          }
          chain inbound {
            type filter hook input priority 0; policy drop;
            icmp type echo-request limit rate 5/second accept
            ct state vmap { { established \
                            , related     } : accept \
                          , invalid         : drop   }
            meta iifname vmap { lo                : accept          \
                              , ${lan.interface} : jump inbound_lan \
                              , ${wan.interface} : jump inbound_wan \
                              , ${iot.interface} : jump inbound_iot }
          }

          chain forward {
            type filter hook input priority 0; policy drop;
            ct state vmap { { established \
                            , related     } : accept \
                            , invalid       : drop   }
            meta oifname ${lan.interface} accept
            meta iifname ${wan.interface} accept
            meta iifname ${iot.interface} meta oifname ${iot.interface} accept
          }
        }

        table ip nat {
          chain postrouting {
            type nat hook postrouting priority 100; policy accept;
            meta oifname ${lan.interface} masquerade
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

    firewall.enable = false;
  };
}

