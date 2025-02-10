{...}: {
  personal.nix = {
    enable = true;
    autoUpgrade.enable = true;
    gc.enable = true;
    flake = "git+file:///etc/nixos/";
    remoteBuilds = {
      enable = true;
      machines.hephaistos = {
        enable = true;
        domain = "local";
      };
    };
  };
  # disable local builds
  nix.settings.max-jobs = 0;
  nixpkgs.flake = {
    setNixPath = true;
    setFlakeRegistry = true;
  };
  system.autoUpgrade.flags = [
    # for reading secrets from a file
    "--impure"
  ];
}
