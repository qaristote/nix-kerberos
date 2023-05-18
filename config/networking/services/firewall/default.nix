{ config, lib, ... }:

let
  # { any } -> (string -> any -> [ string ]) -> string
  mapAttrsStrings = attrs: f: lib.concatStrings (lib.mapAttrsToList f attrs);
  bracket = title: content:
    ''
      ${title} {
    '' + content + ''
      }
    '';
in {
  boot.kernel.sysctl = { "net.ipv4.conf.all.forwarding" = true; };

  networking = {
    nftables = {
      enable = true;
      ruleset = mapAttrsStrings
        (import ./ruleset.nix config.personal.networking.networks)
        (family: tables:
          mapAttrsStrings tables (tableName: chains:
            bracket "table ${family} ${tableName}" (mapAttrsStrings chains
              (chainName: chain:
                bracket "chain ${chainName}" (lib.optionalString (chain ? base)
                  (with chain.base; ''
                    type ${type} hook ${hook} priority ${priority}; policy ${policy};
                  '') + chain.rules)))));
    };
    firewall.enable = lib.mkForce false;
  };
}
