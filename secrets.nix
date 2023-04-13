{
  wifi = {
    iot = {
      passphrase = builtins.readFile "/etc/hostapd/hostapd.iot.pw";
    };
    wan = {
      passphrase = builtins.readFile "/etc/hostapd/hostapd.wan.pw";
    };
  };
}
