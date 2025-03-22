{...}: {
  personal.nix = {
    enable = true;
    gc.enable = true;
  };

  nixpkgs.flake = {
    setNixPath = true;
    setFlakeRegistry = true;
  };
}
