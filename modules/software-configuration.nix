{ config, pkgs, ... }:

{ 
  environment.systemPackages = with pkgs; [
    curl 
    wget 
    socat
    jq
    sing-box
    docker-compose
  ];

  programs = {
    fish.enable = true;
    hyprland.enable = true; 
  };

  virtualisation.docker = {
    enable = true;
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
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
    enable32Bit = true;
    extraPackages = with pkgs; [              
      libvdpau-va-gl      
      libva-vdpau-driver
    ];
  };

  systemd.services.lactd.enable = true;
}