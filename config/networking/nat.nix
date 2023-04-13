{ config, ... }:

let cfg = config.personal.networking;
in {
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.forwarding" = true;
  };

  networking = {
    nat = {
      enable = true;
      externalInterface = cfg.interfaces.eth;
      internalInterfaces = [
        cfg.interfaces.wlp2ghz
        cfg.interfaces.wlp5ghz
      ];
    };

    firewall.enable = false;
  };
}
