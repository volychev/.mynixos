{ config, ... }:

{
  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
    firewall = {
      allowedTCPPorts = [ 1080 ];
      allowedUDPPorts = [ 1080 ];
    };
  };

  services = {
    sing-box = {
      enable = true;
      settings = builtins.fromJSON (builtins.readFile ../vless-config.json);
    };
  };

  systemd.services.nix-daemon.environment = {
    http_proxy = "http://127.0.0.1:1080";
    https_proxy = "http://127.0.0.1:1080";
    no_proxy = "localhost,127.0.0.1,localaddress,.localdomain.com";
  };

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true; 
}