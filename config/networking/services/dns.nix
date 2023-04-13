{ config, ... }:

let cfg = config.personal.networking;
in {
  services.unbound = {
    enable = true;
    settings = {
      server = {
        interface =
          [ "127.0.0.1" "${cfg.subnets.private}.1" "${cfg.subnets.iot}.1" ];
        access-control = [
          "0.0.0.0/0 refuse"
          "127.0.0.0/8 allow"
          "${cfg.subnets.private}.0/24 allow"
          "${cfg.subnets.iot}.0/24 allow"
        ];
      };
    };
  };
}
