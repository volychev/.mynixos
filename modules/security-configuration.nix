{ config, ... }:

{
  security.sudo.extraRules = [{
    users = [ "kirill" ];
    commands = [{
        command = "/etc/profiles/per-user/kirill/bin/touchscreen-innhibit"; 
        options = [ "NOPASSWD" ];
    }];
  }];

  security.polkit.enable = true;
}