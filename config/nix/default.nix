{lib, ...}: {
  imports = [./remote-builds.nix];

  personal.nix = {
    enable = true;
    autoUpgrade.enable = true;
    gc.enable = true;
    flake = "git+file:///etc/nixos/";
  };
  nix.settings.max-jobs = lib.mkDefault 1;
  nixpkgs.flake = {
    setNixPath = true;
    setFlakeRegistry = true;
  };
  system.autoUpgrade.flags = [
    # for reading secrets from a file
    "--impure"
  ];
}
