{
  inputs = {
    my-nixpkgs.url = "github:qaristote/my-nixpkgs";
    nixpkgs.url = "github:NixOS/nixpkgs/release-24.05";
    nixpkgs-beta.url = "github:NixOS/nixpkgs/release-24.11";
  };

  outputs = {
    nixpkgs,
    nixpkgs-beta,
    my-nixpkgs,
    nixos-hardware,
    ...
  }: {
    nixosConfigurations = let
      system = "x86_64-linux";
      commonModules = [
        my-nixpkgs.nixosModules.personal
        ({...}: {nixpkgs.overlays = [my-nixpkgs.overlays.personal (_: _: {inherit (nixpkgs-beta.legacyPackages."${system}") nixos-rebuild;})];})
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
