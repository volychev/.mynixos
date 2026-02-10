{ config, pkgs, ... }: 

{
  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
    firewall.enable = false;
  }; 
  
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true; 
}