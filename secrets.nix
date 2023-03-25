{
  wifi = {
    "2ghz" = {
      passphrase = builtins.readFile "/etc/hostapd/hostapd.2ghz.pw";
    };
    "5ghz" = {
      passphrase = builtins.readFile "/etc/hostapd/hostapd.5ghz.pw";
    };
  };
}
