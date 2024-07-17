{
  config,
  pkgs,
  ...
}: let
  iface = config.personal.networking.networks.eth0.device;
  dhcpService = "kea-dhcp4-server.service";
  action = pkgs.writeShellApplication {
    name = "ifplugd-enp3s0.action";
    runtimeInputs = [pkgs.systemd];
    text = ''
      INTERFACE="$1"
      EVENT="$2"

      if [[ "$INTERFACE" == '${iface}' && "$EVENT" == up ]]
      then
        echo ${iface} went up, restarting ${dhcpService}...
        systemctl restart ${dhcpService}
      fi
    '';
  };
in {
  systemd.services."ifplugd-${iface}" = {
    enable = true;

    description = "Monitor status of interface ${iface}";
    after = ["sys-subsystem-net-devices-${iface}.device" dhcpService];
    wantedBy = [dhcpService];

    script = ''
      #       iface       no-daemon no-auto no-shutdown delay-up run
      ifplugd -i ${iface} -n        -a      -q          -u 5     -r \
              ${action}/bin/ifplugd-enp3s0.action
    '';
    path = [pkgs.busybox];
  };
}
