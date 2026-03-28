{ pkgs, ... }:

{
  programs.kitty = {
    enable = true;
    
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 11;
    };

    settings = {
      foreground = "#eceff4"; 
      background = "#0c0d0f"; 
      cursor = "#eceff4";

      color0 = "#1d2026"; 
      color8 = "#4c566a"; 

      color1 = "#bf616a"; 
      color9 = "#d08770"; 

      color2 = "#8fbcbb";
      color10 = "#a3be8c"; 

      color3 = "#ebcb8b";
      color11 = "#eecf9a";

      color4 = "#81a1c1"; 
      color12 = "#88c0d0"; 

      color5 = "#b48ead"; 
      color13 = "#c9a6c1";

      color6 = "#88c0d0";
      color14 = "#94cedd";

      color7 = "#e5e9f0";
      color15 = "#eceff4";

      confirm_os_window_close = 0;
      enable_audio_bell = false;
      window_padding_width = 12;
      
      repaint_delay = 8;
      input_delay = 1;
      sync_to_monitor = true;
    };
  };
}