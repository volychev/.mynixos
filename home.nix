{ inputs, config, pkgs, user, ... }:

{
  imports = [
    inputs.zen-browser.homeModules.beta
    inputs.ags.homeManagerModules.default
    ./modules/user/desktop/mango/mango.nix
    ./modules/user/cli/fastfetch.nix
    ./modules/user/cli/fish.nix
    ./modules/user/cli/kitty.nix
    ./modules/user/cli/git.nix
    ./modules/user/applications/zen.nix
    ./modules/user/development/vscode.nix
    ./modules/user/development/jetbrains/jetbrains.nix 
  ];

  home = {
    username = user;
    homeDirectory = "/home/${user}";
    stateVersion = "25.11";
  };

  home.packages = with pkgs; [  
    # Desktop
    kitty 
    swww

    # CLI
    btop
    
    # GNOME
    gnome-calculator
    gnome-clocks
    gnome-calendar
    gnome-font-viewer
    gnome-graphs
    gnome-secrets
    nautilus
    sushi
    loupe
    snapshot
    amberol
    binary
    eyedropper
    hieroglyphic
    paper-clip
    switcheroo

    # Social
    telegram-desktop 
    discord

    # Development
    vscode-fhs
    # jetbrains.IDE in ./home/jetbrains/jetbrains.nix 

    # Editors
    micro
    obsidian
    libreoffice-qt
    figma-linux
    typst

    # Networking
    throne

    # Theme
    bibata-cursors
    # colloid-icon-theme
    whitesur-gtk-theme
    whitesur-icon-theme
    
    # System
    pamixer        
    pavucontrol     
    brightnessctl
    cliphist
    wl-clipboard
    grim 
    slurp
    swappy

    # CPP
    clang
    llvmPackages.libstdcxxClang
    cmake
    gnumake
    clang-tools
    llvm
    gcovr
    gtest

    # Python
    python313
    python313Packages.pip
    python313Packages.virtualenv
    poetry

    # Java
    jdk21 
    gradle
  ];

  programs.ags = {
    enable = true;
    configDir = ./modules/user/desktop/ags; 

    extraPackages = with inputs.ags.packages.${pkgs.system}; [
      astal4      
      io          
      apps        
      battery     
      network     
      tray        
      wireplumber
      bluetooth
    ];
  };

  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    QT_QPA_PLATFORM = "wayland;xcb";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    QT_AUTO_SCREEN_SCALE_FACTOR = "1";
    QT_SCALE_FACTOR_ROUNDING_POLICY = "PassThrough";
    SDL_VIDEODRIVER = "wayland";
    _JAVA_AWT_WM_NONREPARENTING = "1";
    GTK_THEME = "WhiteSur-Dark"; 
  };

  gtk = {
    enable = true;
    theme = {
      name = "WhiteSur-Dark";
      package = pkgs.whitesur-gtk-theme.override {
        altVariants = [ "all" ];
        themeVariants = [ "default" ];
      };
    };
    iconTheme = {
      name = "WhiteSur";
      package = pkgs.whitesur-icon-theme;
    };
    cursorTheme = {
      name = "Bibata-Modern-Ice";
      package = pkgs.bibata-cursors;
    };
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "WhiteSur-Dark";
      icon-theme = "WhiteSur";
      cursor-theme = "Bibata-Modern-Ice";
    };
    "org/gnome/shell/extensions/user-theme" = {
      name = "WhiteSur-Dark";
    };
  };

  qt = {
    enable = true;
    platformTheme.name = "gtk"; 
    style.name = "adwaita-dark"; 
  };

  programs.home-manager.enable = true;
}
