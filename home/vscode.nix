{ pkgs, ... }:

{
  programs.vscode = {
    enable = true;
    package = pkgs.vscode-fhs;

    profiles.default = {
      extensions = with pkgs.vscode-extensions; [
        ms-python.python
        ms-python.vscode-pylance
        ms-vscode.cpptools
        ms-vscode.cmake-tools
        twxs.cmake
        
        jnoortheen.nix-ide
        mkhl.direnv
        
        arrterian.nix-env-selector
      ];

      userSettings = {
        # Appearance
        "workbench.colorTheme" = "Jetbrains Fleet";
        "workbench.iconTheme" = "vscode-jetbrains-icon-theme-2023-dark";
        "workbench.productIconTheme" = "material-product-icons";
        
        # Editor
        "editor.fontFamily" = "'JetBrainsMono Nerd Font', 'Droid Sans Mono', 'monospace'";
        "editor.minimap.enabled" = true;
        "editor.scrollbar.vertical" = "hidden";
        
        # System
        "telemetry.telemetryLevel" = "off";
        
        # Nix-IDE
        "nix.serverPath" = "nil"; 
        "nix.serverSettings" = {
          "nil" = {
            "formatting" = { "command" = [ "nixpkgs-fmt" ]; };
          };
        };
      };
    };
  };
}