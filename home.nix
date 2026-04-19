{ inputs, config, pkgs, user, ... }:

{
  imports = [
    inputs.zen-browser.homeModules.beta
    ./modules/user/desktop/mango/home.nix

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
    # CLI
    btop
    inxi
    acpi

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
    hieroglyphic
    paper-clip
    kooha
    remmina
    typesetter

    # Social
    telegram-desktop
    discord

    # Development
    vscode-fhs
    # jetbrains.IDE in ./home/jetbrains/jetbrains.nix
    zed-editor

    # ITMO
    anki
    logisim-evolution
    iverilog
    gtkwave
    iverilog
    verilator

    # Editors
    micro
    obsidian
    libreoffice-qt
    figma-linux
    typst

    # AI
    github-copilot-cli
    gemini-cli

    # Networking / Bluetooth
    throne
    overskride

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

    # Go
    go
    gopls
    gotools
  ];

  programs.home-manager.enable = true;
}
