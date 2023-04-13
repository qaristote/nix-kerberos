{ config, ... }:

let cfg = config.personal.networking;
    ifaces = cfg.interfaces;
in {
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.forwarding" = true;
  };

  networking = {
    nftables = {
      enable = true;
      ruleset = ''
      table ip global {
        chain inbound_public {
          icmp type echo-request limit rate 5/second accept
        }
        chain inbound_private {
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
          meta iifname vmap { lo                : accept               \
                            , ${ifaces.eth}     : jump inbound_public  \
                            , ${ifaces.wlp5ghz} : jump inbound_private \
                            , ${ifaces.wlp2ghz} : jump inbound_iot     }
        }

        chain forward {
          type filter hook input priority 0; policy drop;
          ct state vmap { { established \
                          , related     } : accept \
                          , invalid       : drop   }
          meta oifname ${ifaces.eth} accept
          meta iifname ${ifaces.wlp5ghz} accept
          meta iifname ${ifaces.wlp2ghz} meta oifname ${ifaces.wlp2ghz} accept
        }
      }

      table ip nat {
        chain postrouting {
          type nat hook postrouting priority 100; policy accept;
          meta oifname ${ifaces.eth} masquerade
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
 
