{ inputs, config, pkgs, user, ... }:

{
  imports = [
    inputs.ags.homeManagerModules.default
    ./mango/mango.nix
  ];

  home.packages = with pkgs; [
    # Desktop
    kitty
    awww
    xwayland-satellite

    # Theme
    bibata-cursors
    colloid-icon-theme
    whitesur-gtk-theme
    # whitesur-icon-theme

    # System
    pamixer
    pavucontrol
    brightnessctl
    cliphist
    wl-clipboard
    grim
    slurp
    swappy
    zenity
    tesseract
    tesseract5
    qt6.qtwayland
    libsForQt5.qt5.qtwayland
  ];

  programs.ags = {
    enable = true;
    configDir = ./ags;

    extraPackages = with inputs.ags.packages.${pkgs.stdenv.hostPlatform.system}; [
      astal4
      io
      apps
      battery
      network
      tray
      wireplumber
      bluetooth
      notifd
    ];
  };

  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    QT_QPA_PLATFORM = "wayland;xcb";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    QT_ENABLE_HIGHDPI_SCALING = "1";
    QT_AUTO_SCREEN_SCALE_FACTOR = "1";
    QT_SCALE_FACTOR_ROUNDING_POLICY = "RoundPreferFloor";
    SDL_VIDEODRIVER = "wayland";
    _JAVA_AWT_WM_NONREPARENTING = "1";
  };

  gtk = {
    enable = true;
    gtk4.theme = config.gtk.theme;
    theme = {
      name = "WhiteSur-Dark";
      package = pkgs.whitesur-gtk-theme;
    };
    iconTheme = {
      name = "Colloid-Dark";
      package = pkgs.colloid-icon-theme;
    };
    cursorTheme = {
      name = "Bibata-Modern-Ice";
      package = pkgs.bibata-cursors;
    };
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "WhiteSur-Dark";
      icon-theme = "Colloid-Dark";
      cursor-theme = "Bibata-Modern-Ice";
    };
  };

  qt = {
    enable = true;
    platformTheme.name = "gtk";
    style.name = "WhiteSur-Dark";
  };
}
