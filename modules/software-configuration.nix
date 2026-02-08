{ config, pkgs, ... }:

{ 
  environment.systemPackages = with pkgs; [
    curl 
    wget 
    sing-box
  ];

  programs = {
    fish.enable = true;
    hyprland.enable = true; 
  };

  powerManagement.powertop.enable = true;

  services = {
    xserver.xkb = { layout = "us"; variant = ""; };
    displayManager.sddm = { enable = true; wayland.enable = true; };
    dbus.implementation = "broker";
    gvfs.enable = true;
    upower.enable = true;
    printing.enable = true;
    openssh.enable = true;
    pipewire = {
      enable = true;
      pulse.enable = true;
      wireplumber.enable = true;
    };
    ananicy = {
      enable = true;
      package = pkgs.ananicy-cpp;
      rulesProvider = pkgs.ananicy-rules-cachyos;
    };
  };
}