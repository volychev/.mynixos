{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    curl
    wget
    socat
    jq
    duf
    fd
    docker-compose
    ntfs3g
    udiskie
    # nbfc-linux
  ];

  programs = {
  	dconf.enable = true;
    fish.enable = true;
    throne = {
      enable = true;
      tunMode = {
        enable = true;
        setuid = true;
      };
    };
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
    xserver.xkb = {
      layout = "us,ru";
      variant = "";
      options = "grp:alt_shift_toggle";
    };

    displayManager.sddm = {
      enable = true;
      wayland.enable = true;
      # settings.Theme = "sugar-candy";
    };

    dbus.implementation = "broker";
    gvfs.enable = true;
    upower.enable = true;
    openssh.enable = false;
    # printing.enable = false;
    blueman.enable = true;
    fstrim.enable = true;
    libinput.enable = true;
    udisks2.enable = true;

    pipewire = {
      enable = true;
      pulse.enable = true;
      wireplumber.enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
    };
  };

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-wlr
    ];
    config.common.default = [ "gtk" "wlr" ];
  };

  systemd.services.lactd.enable = true;
}
