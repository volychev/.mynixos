{ pkgs, ... }:

{
  services.hyprpaper = {
    enable = true;
    settings = {
      ipc = "on";
      splash = false;
      
      wallpaper = { 
        monitor = "";
        path = "/etc/nixos/home/hyprland/wallpaper.png";
        fit_mode = "cover";
      };
    };
  };
}