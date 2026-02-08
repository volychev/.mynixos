{ config, ... }:

{
  security.sudo.extraRules = [{
    users = [ "kirill" ];
    commands = [{
        command = "/run/current-system/sw/bin/touchscreen-innhibit"; 
        options = [ "NOPASSWD" ];
    }];
  }];
}