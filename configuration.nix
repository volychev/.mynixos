{ config, pkgs, inputs, ... }:

{
  imports = [ 
    ./modules/hardware-configuration.nix 
    ./modules/software-configuration.nix
    ./modules/security-configuration.nix
    ./modules/networking-configuration.nix
  ];

  users.users.kirill = {
    isNormalUser = true;
    description = "kirill";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.fish; 
  };
  
  time.timeZone = "Europe/Moscow";
  i18n.defaultLocale = "en_US.UTF-8";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;
  fonts.packages = [ pkgs.jetbrains-mono ];

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  system.stateVersion = "25.11";
}