{ inputs, config, pkgs, ... }:

{
  imports = [
    inputs.zen-browser.homeModules.beta
    ./home/hyprland/hyprland.nix 
    ./home/hyprland/hypridle.nix 
    ./home/hyprland/hyprpaper.nix 
    ./home/rofi/rofi.nix 
    ./home/waybar.nix
    ./home/kitty.nix
    ./home/fish.nix
    ./home/fastfetch.nix
    ./home/git.nix
    ./home/zen.nix
    ./home/vscode.nix
    ./home/jetbrains/jetbrains.nix 
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

    nemo-with-extensions
    file-roller
    p7zip
    unzip
    unrar

    telegram-desktop 
    discord

    obsidian
    onlyoffice-desktopeditors
    figma-linux

    micro 
    vscode-fhs
    # jetbrains.IDE in ./home/jetbrains/jetbrains.nix 

    clang
    llvmPackages.libstdcxxClang
    cmake
    gnumake

    python313
    python313Packages.pip
    python313Packages.virtualenv
    poetry
    
    jdk21 
    gradle

    grim 
    slurp
    hypridle 
    hyprpaper
    wl-clipboard 
    cliphist
    swappy
    playerctl 
    pamixer        
    pavucontrol     
    brightnessctl   
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
    _JAVA_AWT_WM_NONREPARENTING = "1";
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