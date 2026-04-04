{ config, pkgs, inputs, lib, ... }:
let
  desktopScripts = import ./scripts/desktop-scripts.nix { inherit pkgs; };
  powerScripts = import ./scripts/power-scripts.nix { inherit pkgs; };

  mangoConfig = import ./modules/config.nix { inherit lib; };
  keybinds = import ./modules/keybinds.nix { inherit lib; };
  visuals = import ./modules/visuals.nix { inherit lib; };
  layout = import ./modules/layout.nix { inherit lib; };
  autostart = import ./modules/autostart.nix { inherit lib; };
in {
  home.packages = with pkgs; [
    desktopScripts.mmsg-scroll
    desktopScripts.mmsg-layout-switch
    desktopScripts.ags-interactive-center
    desktopScripts.screenshot
    desktopScripts.screenshot-ocr
    powerScripts.animate-brightness
    powerScripts.power-mode
    powerScripts.screen-idle-daemon
    powerScripts.power-mode-keychord-enter
    powerScripts.power-mode-keychord-select
    wlr-randr
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
