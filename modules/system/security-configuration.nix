{ config, pkgs, user, ... }:

{
  security.sudo.extraRules = [
    {
      users = [ user ];
      commands = [
        {
          command = "${pkgs.systemd}/bin/systemctl start throne";
          options = [ "NOPASSWD" ];
        }
        {
          command = "${pkgs.systemd}/bin/systemctl stop throne";
          options = [ "NOPASSWD" ];
        }
        {
          command = "${pkgs.systemd}/bin/systemctl restart throne";
          options = [ "NOPASSWD" ];
        }
        {
          command = "/run/current-system/sw/bin/power-mode-apply";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  security.polkit.enable = true;
}
