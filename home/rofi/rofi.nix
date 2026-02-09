{ config, pkgs, ... }:

let
  rofi-launcher = pkgs.writeShellScriptBin "rofi-launcher" ''
    ${pkgs.rofi}/bin/rofi \
        -show drun \
        -theme ${./style.rasi}
        -namespace "rofi"
  '';

  rofi-clipboard = pkgs.writeShellScriptBin "rofi-clipboard" ''
    ${pkgs.cliphist}/bin/cliphist list | \
    ${pkgs.rofi}/bin/rofi -dmenu -p "@" -display-columns 2 -theme ${./clipboard-style.rasi} -namespace "rofi" | \
    ${pkgs.cliphist}/bin/cliphist decode | \
    ${pkgs.wl-clipboard}/bin/wl-copy
  '';
in
{
  home.packages = with pkgs; [
    rofi-launcher
    rofi-clipboard
  ];

  # Управление файлами конфигурации напрямую
  xdg.configFile = {
    "rofi/config.rasi".source = ./config.rasi;
    "rofi/launcher/style.rasi".source = ./style.rasi;
    "rofi/clipboard/style.rasi".source = ./clipboard-style.rasi;
    "rofi/colors/custom.rasi".source = ./custom.rasi;
    
    # Создаем shared-файлы, которые импортируются в темах Aditya
    "rofi/shared/colors.rasi".text = ''@import "../colors/custom.rasi"'';
    "rofi/shared/fonts.rasi".source = ./fonts.rasi;
  };

  # Удален блок programs.rofi, так как он конфликтует с xdg.configFile."rofi/config.rasi"
  # Пакет rofi теперь добавлен явно в home.packages выше.
}