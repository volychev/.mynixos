{ pkgs, ... }:

{
  programs.fastfetch = {
    enable = true;
    settings = {
      logo = {
        source = "ChonkySealOS";
        padding = {
          top = 2;
        };
      };
      modules = [
        "break"
        "break"
        "title"
        "separator"
        "os"
        "host"
        "kernel"
        "shell"
        "wm"
        "terminal"
        "break"
        "uptime"
        "packages"
        "localip"
        "locale"
        "break"
        "display"
        "de"
        "cpu"
        "gpu"
        "disk"
        "memory"
        "battery"
        "poweradapter"
        "break"
        "break"
      ];
    };
  };
}