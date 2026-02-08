{ inputs, config, pkgs, ... }:

{
  imports = [
    inputs.zen-browser.homeModules.beta
    ./home/hyprland/hyprland.nix 
    ./home/rofi/rofi.nix 
    ./home/waybar.nix
    ./home/git.nix
    ./home/zen.nix
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
    nautilus 

    telegram-desktop 

    obsidian
    figma-linux

    micro 
    vscode
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

  programs.home-manager.enable = true;
}