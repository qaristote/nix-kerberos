{ config, ... }:

let nets = config.personal.networking.networks;
in {
  services.unbound = {
    enable = true;
    settings = {
      server = {
        module-config = ''"respip validator iterator"'';
        interface =
          [ "127.0.0.1" "${nets.wan.subnet}.1" "${nets.iot.subnet}.1" ];
        access-control = [
          "0.0.0.0/0 refuse"
          "127.0.0.0/8 allow"
          "${nets.wan.subnet}.0/24 allow"
          "${nets.iot.subnet}.0/24 allow"
        ];
      };
      rpz = {
        name = "rpz.oisd.nl";
      };
    };
  };
}
