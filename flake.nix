{
  inputs = {
    my-nixpkgs.url = "github:qaristote/my-nixpkgs";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
  };

  outputs = {
    nixpkgs,
    my-nixpkgs,
    nixos-hardware,
    ...
  }: {
    nixosConfigurations = let
      system = "x86_64-linux";
      commonModules = [
        my-nixpkgs.nixosModules.personal
        ({...}: {nixpkgs.overlays = [my-nixpkgs.overlays.personal];})
      ];
    in {
      kerberos = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = commonModules ++ [./config];
        specialArgs = {
          inherit nixos-hardware;
        };
      };
    };
  };
}
