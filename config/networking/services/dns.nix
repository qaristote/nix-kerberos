{config, ...}: let
  subnets = builtins.catAttrs "subnet" (builtins.attrValues config.personal.networking.interfaces.all);
in {
  services.unbound = {
    enable = true;
    settings = {
      server = {
        module-config = ''"respip validator iterator"'';
        interface =
          [
            "127.0.0.1"
          ]
          ++ builtins.map ({prefix, ...}: "${prefix}.1") subnets;
        access-control =
          [
            "0.0.0.0/0 refuse"
            "127.0.0.0/8 allow"
          ]
          ++ builtins.map ({
            prefix,
            prefixLength,
          }: "${prefix}.0/${builtins.toString prefixLength} allow")
          subnets;
      };
      rpz.name = "rpz.oisd.nl";
    };
  };
}
