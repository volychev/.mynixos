{ pkgs, ... }:

{
  programs.vscode = {
    enable = true;
    package = pkgs.vscode-fhs;

    profiles.default = {
      extensions = (with pkgs.vscode-extensions; [
        ms-python.python
        ms-python.vscode-pylance
        ms-vscode.cpptools
        ms-vscode.cmake-tools
        twxs.cmake
        
        jnoortheen.nix-ide
        mkhl.direnv
      ]) ++ (with pkgs.vscode-marketplace; [
        arrterian.nix-env-selector
        chadalen.vscode-jetbrains-icon-theme
        michaelzhou.fleet-theme
        ms-vscode.cpptools-extension-pack
        ms-vscode.cpptools-themes
        narasimapandiyan.jetbrainsmono
        pinage404.nix-extension-pack
      ]);

      userSettings = {
        # Appearance
        "workbench.colorTheme" = "Jetbrains Fleet";
        "workbench.iconTheme" = "vscode-jetbrains-icon-theme";
        "workbench.productIconTheme" = "material-product-icons";
        
        # Editor
        "editor.fontFamily" = "'JetBrainsMono Nerd Font', 'Droid Sans Mono', 'monospace'";
        "editor.minimap.enabled" = true;
        "editor.scrollbar.vertical" = "hidden";
        
        # System
        "telemetry.telemetryLevel" = "off";
        
        # Nix-IDE specific (полезно добавить)
        "nix.enableLanguageServer" = true;
        "nix.serverPath" = "nil"; # или "nixd"
      };
    };
  };
}