{ config, lib, ... }:

let
  # { any } -> (string -> any -> string) -> string
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
      checkRuleset = false;
      ruleset = mapAttrsStrings (import ./ruleset.nix {
        inherit lib;
        nets = config.personal.networking.networks;
      }) (family: tables:
        mapAttrsStrings tables (tableName:
          { flowtables, chains, ... }:
          bracket "table ${family} ${tableName}" (
            mapAttrsStrings flowtables
              (flowtableName: flowtable:
                bracket "flowtable ${flowtableName}" (with flowtable;
                  ''
                    hook ${hook} priority ${priority}; devices = { ${
                      lib.concatStringsSep ", " devices
                    } };
                  '' + lib.optionalString offload ''
                    flags offload;
                  ''
                )
              )
            + mapAttrsStrings chains (chainName: chain:
                  bracket "chain ${chainName}" (
                    lib.optionalString (chain ? base) (with chain.base; ''
                      type ${type} hook ${hook} priority ${priority}; policy ${policy};
                    '')
                    + chain.rules
                  )
            )
          )
        )
      );
    };
    firewall.enable = lib.mkForce false;
  };
}
