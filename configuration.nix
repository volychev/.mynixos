{ config, pkgs, inputs, lib, ... }:

{
  imports = [ 
    ./modules/hardware-configuration.nix 
    ./modules/software-configuration.nix
    ./modules/security-configuration.nix
    ./modules/networking-configuration.nix
    ./modules/power-configuration.nix
    ./modules/filesystem-configuration.nix
  ];

  users.users.kirill = {
    isNormalUser = true;
    description = "kirill";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    shell = pkgs.fish; 
  };
  
  time.timeZone = "Europe/Moscow";
  i18n.defaultLocale = "en_US.UTF-8";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.auto-optimise-store = true;
  
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  nixpkgs.config.allowUnfree = true;

  boot.kernelPackages = pkgs.linuxPackages_zen;

  fonts.packages = with pkgs; [
    corefonts 
    vista-fonts
    jetbrains-mono
    nerd-fonts.jetbrains-mono
  ];

  boot = {
    loader.systemd-boot.configurationLimit = 5;
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernelParams = [
      "amd_pstate=active"
      "8250.nr_uarts=0"
      "iommu=pt"
      "nvme_core.default_ps_max_latency_us=0"
      "amdgpu.ppfeaturemask=0xffffffff"
      "amdgpu.dcdebugmask=0x10"
      "amdgpu.sg_display=0"
    ];
    kernel.sysctl = {
      "net.core.default_qdisc" = "fq";
      "net.ipv4.tcp_congestion_control" = "bbr";
      "vm.swappiness" = 10;
      "kernel.sched_autogroup_enabled" = 0;
      "kernel.nmi_watchdog" = 0;
      "vm.laptop_mode" = 5;
      "vm.dirty_writeback_centisecs" = 6000;
    };
    extraModprobeConfig = ''
      options snd_hda_intel power_save=1 
    '';
  };

  zramSwap = {
    enable = true;
    memoryPercent = 50;
  };
  
  system.stateVersion = "25.11";
}