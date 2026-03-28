{ config, pkgs, inputs, lib, hostname, user, ... }:

{
  imports = [ 
    ./hosts/${hostname}/hardware-configuration.nix 
    ./hosts/${hostname}/boot-configuration.nix 
    ./hosts/${hostname}/filesystem-configuration.nix 
    ./hosts/${hostname}/system-configuration.nix 
    ./modules/software-configuration.nix
    ./modules/system/networking-configuration.nix
    ./modules/system/power-configuration.nix
    ./modules/system/security-configuration.nix
    ./modules/user/desktop/font-configuration.nix
  ];
  
  users.users.${user} = {
    isNormalUser = true;
    description = "Kirill Volychev";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    shell = pkgs.fish; 
  };

  time.timeZone = "Europe/Moscow";
  i18n.defaultLocale = "en_US.UTF-8";

  nixpkgs.config.allowUnfree = true;
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  system.stateVersion = "25.11";
}
