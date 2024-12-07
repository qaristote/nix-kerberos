{...}: {
  programs.ssh = {
    extraConfig = ''
      Host hephaistos.local
        # Prevent using ssh-agent or another keyfile, useful for testing
        IdentitiesOnly yes
        IdentityFile /root/.ssh/nixremote
        # The weakly privileged user on the remote builder – if not set, 'root' is used – which will hopefully fail
        User nixremote
    '';
    knownHosts."hephaistos.local".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHvtqi8tziBuviUV8LDK2ddQQUbHdJYB02dgWTK5Olxq";
  };

  nix = {
    distributedBuilds = true;
    buildMachines = [
      {
        hostName = "hephaistos.local";
        system = "x86_64-linux";
        # Nix custom ssh-variant that avoids lots of "trusted-users" settings pain
        protocol = "ssh-ng";
        maxJobs = 4;
        speedFactor = 4;
        supportedFeatures = ["nixos-test" "benchmark" "big-parallel" "kvm"];
        mandatoryFeatures = [];
      }
    ];
  };
}
