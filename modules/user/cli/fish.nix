{ pkgs, ... }:

{
  programs.fish = {
    enable = true;
    
    interactiveShellInit = ''
      set -g fish_greeting ""
      fastfetch
    '';
    
    shellAliases = {
      cdconf = "cd /etc/nixos";
      upd = "sudo nixos-rebuild switch";
    };
  };
}