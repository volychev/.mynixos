{ config, pkgs, ... }:

{ 
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;

    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 5;
        consoleMode = "max"; 
      };
      efi.canTouchEfiVariables = true;
    };
    
    kernelParams = [
      "amd_pstate=active"
      "iommu=pt"
      "kernel.nmi_watchdog=0" 

      "amdgpu.ppfeaturemask=0xffffffff"
      "amdgpu.sg_display=0"
      "amdgpu.dcdebugmask=0x400"
      "amdgpu.abmlevel=0"
    ];

    kernel.sysctl = {
      "net.core.default_qdisc" = "fq";
      "net.ipv4.tcp_congestion_control" = "bbr";
      "vm.swappiness" = 180; 
      "vm.page-cluster" = 0;
      "vm.laptop_mode" = 5;
      "vm.dirty_writeback_centisecs" = 6000;
    };

    extraModprobeConfig = ''
      options snd_hda_intel power_save=1 
    '';
  };
}
