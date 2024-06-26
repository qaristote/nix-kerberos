{
  config,
  lib,
  utils,
  pkgs,
  secrets,
  ...
}: let
  nets = config.personal.networking.networks;
  makeHostapdConf = {
    name,
    device,
    interface,
    driver ? "nl80211",
    ssid,
    hwMode ? "g",
    channel ? 0,
    countryCode ? "FR",
    passphrase ? secrets.wifi."${name}".passphrase,
    logLevel ? 2,
    extraConfig ? "",
  }:
    builtins.toFile "hostapd.${name}.conf" (''
        interface=${device}
        driver=${driver}

        # IEEE 802.11
        ssid=${ssid}
        hw_mode=${hwMode}
        channel=${toString channel}
        max_num_sta=128
        auth_algs=1
        disassoc_low_ack=1

        # DFS
        ieee80211h=1
        ieee80211d=1
        country_code=${countryCode}

        # disable low-level bridging of frames
        ap_isolate=1
        bridge=${interface}

        # WPA/IEEE 802.11i
        wpa=2
        wpa_key_mgmt=WPA-PSK
        wpa_passphrase=${passphrase}
        wpa_pairwise=CCMP

        # hostapd event logger configuration
        logger_syslog=-1
        logger_syslog_level=${toString logLevel}
        logger_stdout=-1
        logger_stdout_level=${toString logLevel}

        # WMM
        wmm_enabled=1
        uapsd_advertisement_enabled=1
        wmm_ac_bk_cwmin=4
        wmm_ac_bk_cwmax=10
        wmm_ac_bk_aifs=7
        wmm_ac_bk_txop_limit=0
        wmm_ac_bk_acm=0
        wmm_ac_be_aifs=3
        wmm_ac_be_cwmin=4
        wmm_ac_be_cwmax=10
        wmm_ac_be_txop_limit=0
        wmm_ac_be_acm=0
        wmm_ac_vi_aifs=2
        wmm_ac_vi_cwmin=3
        wmm_ac_vi_cwmax=4
        wmm_ac_vi_txop_limit=94
        wmm_ac_vi_acm=0
        wmm_ac_vo_aifs=2
        wmm_ac_vo_cwmin=2
        wmm_ac_vo_cwmax=3
        wmm_ac_vo_txop_limit=47
        wmm_ac_vo_acm=0

        # TX queue parameters
        tx_queue_data3_aifs=7
        tx_queue_data3_cwmin=15
        tx_queue_data3_cwmax=1023
        tx_queue_data3_burst=0
        tx_queue_data2_aifs=3
        tx_queue_data2_cwmin=15
        tx_queue_data2_cwmax=63
        tx_queue_data2_burst=0
        tx_queue_data1_aifs=1
        tx_queue_data1_cwmin=7
        tx_queue_data1_cwmax=15
        tx_queue_data1_burst=3.0
        tx_queue_data0_aifs=1
        tx_queue_data0_cwmin=3
        tx_queue_data0_cwmax=7
        tx_queue_data0_burst=1.5
      ''
      + extraConfig);
  hostapdIotConf = makeHostapdConf {
    name = "iot";
    inherit (nets.iot) device interface;
    ssid = "Quentinternet of Things";
    hwMode = "g";
    channel = 0;
    extraConfig = ''
      # IEEE 802.11n
      ieee80211n=1
      require_ht=0 # sonos play:1 doesn't support ht
      ht_capab=[HT40+][SHORT-GI-40][TX-STBC][RX-STBC1][DSSS_CCK-40]
    '';
  };
  hostapdWanConf = makeHostapdConf {
    name = "wan";
    inherit (nets.wan) device interface;
    ssid = "Quentintranet";
    hwMode = "a";
    channel = 36;
    extraConfig = ''
      # IEEE 802.11n
      ieee80211n=1
      require_ht=1
      ht_capab=[HT40+][LDPC][SHORT-GI-20][SHORT-GI-40][TX-STBC][RX-STBC1][DSSS_CCK-40]

      # IEEE 802.11ac
      require_vht=1
      ieee80211ac=1
      vht_oper_chwidth=1
      vht_oper_centr_freq_seg0_idx=42
      vht_capab=[MAX-MPDU-11454][RXLDPC][SHORT-GI-80][TX-STBC-2BY1][RX-STBC-1][MAX-A-MPDU-LEN-EXP7][RX-ANTENNA-PATTERN][TX-ANTENNA-PATTERN]
    '';
  };
in {
  systemd.services.hostapd = let
    subnets = with nets; [wan iot];
    netDevices =
      builtins.map (subnet: "sys-subsystem-net-devices-${
        utils.escapeSystemdPath subnet.device
      }.device")
      subnets;
    netdevServices =
      builtins.map (subnet: "${subnet.interface}-netdev.service") subnets;
    dependencies = lib.mkForce (netDevices ++ netdevServices);
  in
    lib.mkForce {
      # from https://github.com/NixOS/nixpkgs/blob/23.05/nixos/modules/services/networking/hostapd.nix
      # with hardening from https://github.com/NixOS/nixpkgs/blob/23.11/nixos/modules/services/networking/hostapd.nix
      description = "IEEE 802.11 Host Access-Point Daemon";

      path = [pkgs.hostapd];
      after = dependencies;
      bindsTo = dependencies;
      wantedBy = ["multi-user.target"];

      serviceConfig = {
        ExecStart = "${pkgs.hostapd}/bin/hostapd ${hostapdIotConf} ${hostapdWanConf}";
        Restart = "always";
        ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
        RuntimeDirectory = "hostapd";

        # Hardening
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        DevicePolicy = "closed";
        DeviceAllow = "/dev/rfkill rw";
        NoNewPrivileges = true;
        PrivateUsers = false; # hostapd requires true root access.
        PrivateTmp = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectProc = "invisible";
        ProcSubset = "pid";
        ProtectSystem = "strict";
        RestrictAddressFamilies = ["AF_INET" "AF_INET6" "AF_NETLINK" "AF_UNIX" "AF_PACKET"];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
        SystemCallFilter = ["@system-service" "~@privileged" "@chown"];
        UMask = "0077";
      };
    };
}
