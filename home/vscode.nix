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

        dracula-theme.theme-dracula
        pkief.material-product-icons
      ];

      userSettings = {
        "workbench.colorTheme" = "Dracula"; 
        "workbench.productIconTheme" = "material-product-icons";
        "workbench.iconTheme" = "material-design-icons";
        "editor.fontFamily" = "'JetBrainsMono Nerd Font', 'Droid Sans Mono', 'monospace'";
  
        "editor.minimap.enabled" = true;
        "editor.scrollbar.vertical" = "hidden";
        
        "telemetry.telemetryLevel" = "off";
      };
    };
  };
}