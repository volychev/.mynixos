{ config, pkgs, inputs, lib, ... }:
let
  mmsg-scroll = pkgs.writeShellScriptBin "mmsg-scroll" ''
    OUTPUT=$(mmsg -g -l | tr -d '[:space:]')
    
    LAST_CHAR=''${OUTPUT: -1}

    if [ "$LAST_CHAR" = "S" ]; then
        if [ "$1" = "up" ]; then
            mmsg -d focusstack,next
        elif [ "$1" = "down" ]; then
            mmsg -d focusstack,prev
        fi
    else
        mmsg -d toggleoverview
    fi
  '';

  mmsg-layout-switch = pkgs.writeShellScriptBin "mmsg-layout-switch" ''
    OUTPUT=$(mmsg -g -l | tr -d '[:space:]')
    
    LAST_CHAR=''${OUTPUT: -1}

    if [ "$LAST_CHAR" = "S" ]; then
        mmsg -l T
    else
        mmsg -l VS
    fi
  '';

  config = import ./modules/config.nix { inherit lib; };	
  keybinds = import ./modules/keybinds.nix { inherit lib; };
  visuals = import ./modules/visuals.nix { inherit lib; };
  layout = import ./modules/layout.nix { inherit lib; };	
  autostart = import ./modules/autostart.nix { inherit lib; };
in {
  home.packages = with pkgs; [
    mmsg-scroll
    mmsg-layout-switch
  ];

  imports = [
    inputs.mango.hmModules.mango
  ];
  
  wayland.windowManager.mango = {
    enable = true;

    settings = lib.concatStringsSep "\n" [
      config
      keybinds	
      layout
      visuals
      autostart
    ];
  };
}
