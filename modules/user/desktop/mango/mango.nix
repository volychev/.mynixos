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

  ags-interactive-center = pkgs.writeShellScriptBin "ags-interactive-center" ''
    MODE="$1"
    if [ -z "$MODE" ]; then
      exit 1
    fi

    ags request --instance ags interactive-center "$MODE"
  '';

  screenshot = pkgs.writeShellScriptBin "screenshot" ''
    SLURP_ARGS="-b 00000066 -c 00000000 -B BFb4faff -w 2"
    TEMP_IMG="/tmp/screenshot_$(date +%s).png"
    GEOM=$(slurp $SLURP_ARGS)

    if [ -z "$GEOM" ]; then
        exit 0
    fi

    if grim -g "$GEOM" "$TEMP_IMG"; then
        wl-copy --type image/png < "$TEMP_IMG"
        swappy -f "$TEMP_IMG" && rm "$TEMP_IMG"
    else
        exit 1
    fi
  '';

  mangoConfig = import ./modules/config.nix { inherit lib; };
  keybinds = import ./modules/keybinds.nix { inherit lib; };
  visuals = import ./modules/visuals.nix { inherit lib; };
  layout = import ./modules/layout.nix { inherit lib; };
  autostart = import ./modules/autostart.nix { inherit lib; };
in {
  home.packages = with pkgs; [
    mmsg-scroll
    mmsg-layout-switch
    ags-interactive-center
    screenshot
  ];

  imports = [
    inputs.mango.hmModules.mango
  ];

  wayland.windowManager.mango = {
    enable = true;

    extraConfig = lib.concatStringsSep "\n" [
      mangoConfig
      keybinds
      layout
      visuals
      autostart
    ];
  };
}
