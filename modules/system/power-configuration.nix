{ pkgs, ... }:

{
  services = {
    tlp = {
      enable = true;
      settings = {
        CPU_SCALING_GOVERNOR_ON_AC  = "powersave";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

        CPU_ENERGY_PERF_POLICY_ON_AC  = "performance"; 
        CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

        WIFI_PWR_ON_AC  = "off";
        WIFI_PWR_ON_BAT = "on";

        USB_AUTOSUSPEND = 1;
        PCIE_ASPM_ON_AC  = "performance";
        PCIE_ASPM_ON_BAT = "powersave"; 

        SOUND_POWER_SAVE_ON_AC  = 0;
        SOUND_POWER_SAVE_ON_BAT = 1;

        DISK_DEVICES = "nvme0n1";
        DISK_IOSCHED = "none"; 
      };
    };

    ananicy = {
      enable = true;
      package = pkgs.ananicy-cpp;
      rulesProvider = pkgs.ananicy-rules-cachyos; 
    };

    scx = {
      enable = true;
      scheduler = "scx_rusty";
    };
  };

  powerManagement.powertop.enable = false;
  services.power-profiles-daemon.enable = false;
}
