{ config, pkgs, inputs, ... }:

{
  fonts.packages = with pkgs; [
    corefonts
    vista-fonts
    inter
    inputs.apple-fonts.packages.${pkgs.system}.sf-pro
    jetbrains-mono
    nerd-fonts.jetbrains-mono
    nerd-fonts.symbols-only
  ];
}
