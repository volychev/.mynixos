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

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    neocmakelsp
    gopls
  ];

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
    dbus.implementation = "broker";
    gvfs.enable = true;
    upower.enable = true;
    openssh.enable = false;
    # printing.enable = false;
    # blueman.enable = false;
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
