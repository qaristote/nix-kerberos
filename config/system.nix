{...}: {
  personal.system = {
    flake = "git+file:///etc/nixos/";
    autoUpgrade = {
      enable = true;
      remoteBuilding = {
        enable = true;
        builder.domain = "local";
      };
    };
  };

  system.autoUpgrade = {
    allowReboot = true;
    dates = "02:00";
  };
}
