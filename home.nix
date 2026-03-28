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
    colloid-icon-theme
    
    # System
    pamixer        
    pavucontrol     
    brightnessctl
    cliphist
    wl-clipboard

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
      io          # Базовый ввод-вывод
      apps        # Список приложений
      battery     # Батарея
      mpris       # Плеер
      network     # Сеть
      tray        # Трей
      wireplumber # Звук
      bluetooth
    ];
  };

  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    _JAVA_AWT_WM_NONREPARENTING = "1";
    QT_QPA_PLATFORM = "wayland;xcb";
    SDL_VIDEODRIVER = "wayland";
  };

  gtk = {
    enable = true;
    # theme = {
    #   name = "WhiteSur-Dark";
    #   package = pkgs.whitesur-gtk-theme;
    # };
    iconTheme = {
      name = "Colloid-Dark";
      package = pkgs.colloid-icon-theme;
    };
    cursorTheme = {
      name = "Bibata-Modern-Ice";
      package = pkgs.bibata-cursors;
    };
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      # gtk-theme = "WhiteSur-Dark";
      icon-theme = "Colloid-Dark";
    };
  };

  qt = {
    enable = true;
    platformTheme.name = "gtk"; 
    style.name = "adwaita-dark"; 
  };

  programs.home-manager.enable = true;
}
