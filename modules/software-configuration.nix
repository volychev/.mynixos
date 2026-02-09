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

  services = {
    xserver.xkb = { layout = "us"; variant = ""; };
    displayManager.sddm = { enable = true; wayland.enable = true; };
    dbus.implementation = "broker";
    gvfs.enable = true;
    upower.enable = true;
    printing.enable = true;
    openssh.enable = true;
    blueman.enable = true;
    fstrim.enable = true;
    libinput.enable = true;
    pipewire = {
      enable = true;
      pulse.enable = true;
      wireplumber.enable = true;
    };
  };
  
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [              
      libvdpau-va-gl      
      libva-vdpau-driver
    ];
  };

  systemd.services.lactd.enable = true;
}