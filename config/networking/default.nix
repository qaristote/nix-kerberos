{ pkgs, ... }:

{
  personal.networking = {
    enable = true;
    ssh.enable = true;
  };

  networking = {
    hostName = "kerberos";
    domain = "local";
  };
}
