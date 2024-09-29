{
  config,
  lib,
  ...
}: let
  ifaces = config.personal.networking.interfaces.all;
  netdevServices = builtins.map (bridge: "${bridge}-netdev.service") ["wan" "iot" "guest"];

  # common config
  countryCode = "FR";
  driver = "nl80211";
  settings.max_num_sta = 128;
  perBridgeCfg = radio: bridge: let
    ssids = {
      wan = "Quentintranet";
      iot = "Quentinternet of Things";
      guest = "Quentinvités";
    };
    iface = radio + lib.optionalString (bridge != "wan") "-${bridge}";
  in {
    "${iface}" = {
      ssid = ssids."${bridge}" + lib.optionalString (radio == "wlp5s0" && bridge != "guest") " (n)";
      bssid = ifaces."${iface}".machines.self.mac;

      authentication.mode = "wpa3-sae";
      authentication.saePasswordsFile = "/etc/hostapd/${bridge}.sae";

      logLevel = 2; # informational messages

      apIsolate = true;
      settings = {
        inherit bridge;

        disassoc_low_ack = 1;
        # WMM
        wmm_enabled = 1;
        uapsd_advertisement_enabled = 1;
        wmm_ac_bk_cwmin = 4;
        wmm_ac_bk_cwmax = 10;
        wmm_ac_bk_aifs = 7;
        wmm_ac_bk_txop_limit = 0;
        wmm_ac_bk_acm = 0;
        wmm_ac_be_aifs = 3;
        wmm_ac_be_cwmin = 4;
        wmm_ac_be_cwmax = 10;
        wmm_ac_be_txop_limit = 0;
        wmm_ac_be_acm = 0;
        wmm_ac_vi_aifs = 2;
        wmm_ac_vi_cwmin = 3;
        wmm_ac_vi_cwmax = 4;
        wmm_ac_vi_txop_limit = 94;
        wmm_ac_vi_acm = 0;
        wmm_ac_vo_aifs = 2;
        wmm_ac_vo_cwmin = 2;
        wmm_ac_vo_cwmax = 3;
        wmm_ac_vo_txop_limit = 47;
        wmm_ac_vo_acm = 0;
        # TX queue
        tx_queue_data3_aifs = 7;
        tx_queue_data3_cwmin = 15;
        tx_queue_data3_cwmax = 1023;
        tx_queue_data3_burst = 0;
        tx_queue_data2_aifs = 3;
        tx_queue_data2_cwmin = 15;
        tx_queue_data2_cwmax = 63;
        tx_queue_data2_burst = 0;
        tx_queue_data1_aifs = 1;
        tx_queue_data1_cwmin = 7;
        tx_queue_data1_cwmax = 15;
        tx_queue_data1_burst = "3.0";
        tx_queue_data0_aifs = 1;
        tx_queue_data0_cwmin = 3;
        tx_queue_data0_cwmax = 7;
        tx_queue_data0_burst = "1.5";
      };
    };
  };
in {
  systemd.services.hostapd = {
    after = netdevServices;
    bindsTo = netdevServices;
  };

  services.hostapd = {
    enable = true;
    radios = {
      wlp1s0 = {
        inherit countryCode driver;
        band = "5g";
        channel = 36;
        wifi4 = {
          enable = true;
          require = true;
          capabilities = ["HT40+" "LDPC" "SHORT-GI-20" "SHORT-GI-40" "TX-STBC" "RX-STBC1" "DSSS_CCK-40"];
        };
        wifi5 = {
          enable = true;
          require = true;
          operatingChannelWidth = "80";
          capabilities = ["MAX-MPDU-11454" "RXLDPC" "SHORT-GI-80" "TX-STBC-2BY1" "RX-STBC-1" "MAX-A-MPDU-LEN-EXP7" "RX-ANTENNA-PATTERN" "TX-ANTENNA-PATTERN"];
        };
        settings = settings // {vht_oper_centr_freq_seg0_idx = 42;};

        networks = let
          perBridgeAC = perBridgeCfg "wlp1s0";
        in
          (perBridgeAC "wan") // (perBridgeAC "iot");
      };
      wlp5s0 = {
        inherit countryCode driver settings;
        band = "2g";
        channel = 0;
        wifi4 = {
          enable = true;
          require = false;
          capabilities = ["HT40+" "SHORT-GI-40" "TX-SBTC" "RX-SBTC1" "DSSS_CCK-40"];
        };

        networks = let
          perBridgeN = perBridgeCfg "wlp5s0";
        in
          (perBridgeN "wan")
          // (perBridgeN "iot")
          // (perBridgeN "guest");
      };
    };
  };
}
