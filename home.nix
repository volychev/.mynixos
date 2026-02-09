{ inputs, config, pkgs, ... }:

{
  imports = [
    inputs.zen-browser.homeModules.beta
    ./home/hyprland/hyprland.nix 
    ./home/hyprland/hypridle.nix 
    ./home/rofi/rofi.nix 
    ./home/waybar.nix
    ./home/kitty.nix
    ./home/fish.nix
    ./home/fastfetch.nix
    ./home/git.nix
    ./home/zen.nix
    ./home/vscode.nix
  ];

  home = {
    username = "kirill";
    homeDirectory = "/home/kirill";
    stateVersion = "25.11";
  };

  home.packages = with pkgs; [
    kitty 
    rofi 
    waybar 

    nemo

    telegram-desktop 

    obsidian
    figma-linux

    micro 
    vscode-fhs
    # jetbrains.pycharm
    # jetbrains.clion

    clang
    llvmPackages.libstdcxxClang
    cmake
    gnumake

    python313
    python313Packages.pip
    python313Packages.virtualenv
    poetry
    
    hyprshot 
    hypridle 
    swaybg
    wl-clipboard 
    cliphist
    playerctl 
    libnotify
    pamixer        
    pavucontrol     
    brightnessctl   
    swaynotificationcenter
  ];

  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Ice";
    size = 18;
  };

  home.sessionVariables = {
    NIXOS_OZONE_LAYER = "1";
    GTK_THEME = "Adwaita-dark";
  };

  gtk = {
    enable = true;
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };
    gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = 1;
  };

  qt = {
    enable = true;
    platformTheme.name = "gtk"; 
    style.name = "adwaita-dark";
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };

  programs.home-manager.enable = true;
}