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
          command = "/run/current-system/sw/bin/systemctl start throne";
          options = [ "NOPASSWD" ];
        }
        {
          command = "/run/current-system/sw/bin/systemctl stop throne";
          options = [ "NOPASSWD" ];
        }
        {
          command = "/run/current-system/sw/bin/systemctl restart throne";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  security.polkit.enable = true;
}