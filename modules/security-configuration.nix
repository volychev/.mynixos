{ config, ... }:

{
  security.sudo.extraRules = [
    {
      users = [ "kirill" ];
      commands = [
        {
          command = "/etc/profiles/per-user/kirill/bin/touchscreen-innhibit"; 
          options = [ "NOPASSWD" ];
        }
        {
          command = "/run/current-system/sw/bin/systemctl start sing-box";
          options = [ "NOPASSWD" ];
        }
        {
          command = "/run/current-system/sw/bin/systemctl stop sing-box";
          options = [ "NOPASSWD" ];
        }
        {
          command = "/run/current-system/sw/bin/systemctl restart sing-box";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  security.polkit.enable = true;
}