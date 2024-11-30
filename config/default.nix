{modulesPath, ...}: {
  imports = [
    (modulesPath + "/profiles/minimal.nix")
    ./boot.nix
    ./environment.nix
    ./hardware
    ./networking
    ./nix
    ./users.nix
  ];

  # needed so that the server doesn't rebuild big packages
  # originally enabled in modulesPath + profiles/minimal.nix
  environment.noXlibs = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?
}
