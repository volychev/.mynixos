{ pkgs, ... }:
let
  power-mode-apply = pkgs.writeShellScriptBin "power-mode-apply" ''
    set -euo pipefail

    if [ "$(id -u)" -ne 0 ]; then
      echo "power-mode-apply must be run as root." >&2
      exit 1
    fi

    normalize_mode() {
      case "''${1,,}" in
        ultra-eco|ultra_eco|ultraeco|ultra)
          echo "ultra-eco"
          ;;
        eco)
          echo "eco"
          ;;
        balanced|balance)
          echo "balanced"
          ;;
        performance|perf)
          echo "performance"
          ;;
        *)
          return 1
          ;;
      esac
    }

    write_optional() {
      local path="$1"
      local value="$2"

      if [ ! -e "$path" ]; then
        return 0
      fi
      if [ ! -w "$path" ]; then
        echo "Cannot write $path" >&2
        return 1
      fi

      printf '%s\n' "$value" > "$path"
    }

    apply_tlp_profile() {
      local profile="$1"
      local tlp_bin="/run/current-system/sw/bin/tlp"

      if [ ! -x "$tlp_bin" ]; then
        echo "TLP binary not found at $tlp_bin" >&2
        return 1
      fi

      "$tlp_bin" "$profile" >/dev/null
    }

    apply_platform_profile() {
      local profile="$1"
      local profile_path="/sys/firmware/acpi/platform_profile"
      local choices_path="/sys/firmware/acpi/platform_profile_choices"

      if [ ! -e "$profile_path" ] || [ ! -e "$choices_path" ]; then
        return 0
      fi

      local choices
      choices="$(cat "$choices_path" 2>/dev/null || true)"

      if printf '%s\n' "$choices" | tr ' ' '\n' | grep -qx "$profile"; then
        write_optional "$profile_path" "$profile"
      fi
    }

    apply_cpu_profile() {
      local max_percent="$1"
      local governor="$2"
      local epp="$3"
      local boost="$4"

      local policy0="/sys/devices/system/cpu/cpufreq/policy0"
      if [ ! -d "$policy0" ]; then
        echo "cpufreq policy0 is not available." >&2
        return 1
      fi

      for policy in /sys/devices/system/cpu/cpufreq/policy*; do
        [ -d "$policy" ] || continue

        local policy_cpu_max
        local policy_min
        local target_max
        policy_cpu_max="$(cat "$policy/cpuinfo_max_freq")"
        policy_min="$(cat "$policy/scaling_min_freq")"
        target_max=$((policy_cpu_max * max_percent / 100))
        if [ "$target_max" -lt "$policy_min" ]; then
          target_max="$policy_min"
        fi

        write_optional "$policy/scaling_governor" "$governor"
        write_optional "$policy/energy_performance_preference" "$epp"
        write_optional "$policy/scaling_max_freq" "$target_max"
      done

      write_optional "/sys/devices/system/cpu/cpufreq/boost" "$boost"
    }

    if [ "$#" -ne 1 ]; then
      echo "Usage: power-mode-apply <ultra-eco|eco|balanced|performance>" >&2
      exit 1
    fi

    mode="$(normalize_mode "$1")" || {
      echo "Unknown mode: $1" >&2
      exit 1
    }

    case "$mode" in
      ultra-eco)
        tlp_profile="power-saver"
        governor="powersave"
        epp="power"
        boost="0"
        max_percent="20"
        platform_profile="low-power"
        ;;
      eco)
        tlp_profile="balanced"
        governor="powersave"
        epp="balance_power"
        boost="0"
        max_percent="40"
        platform_profile="low-power"
        ;;
      balanced)
        tlp_profile="balanced"
        governor="powersave"
        epp="balance_performance"
        boost="1"
        max_percent="60"
        platform_profile="balanced"
        ;;
      performance)
        tlp_profile="performance"
        governor="performance"
        epp="performance"
        boost="1"
        max_percent="100"
        platform_profile="performance"
        ;;
    esac

    apply_tlp_profile "$tlp_profile"
    apply_cpu_profile "$max_percent" "$governor" "$epp" "$boost"
    apply_platform_profile "$platform_profile"

    echo "Applied mode: $mode"
  '';
in
{
  environment.systemPackages = [ power-mode-apply ];

  services = {
    tlp = {
      enable = true;
      settings = {
        CPU_SCALING_GOVERNOR_ON_AC  = "powersave";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

        CPU_ENERGY_PERF_POLICY_ON_AC  = "performance";
        CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_performance";

        WIFI_PWR_ON_AC  = "off";
        WIFI_PWR_ON_BAT = "on";

        USB_AUTOSUSPEND = 1;
        PCIE_ASPM_ON_AC  = "performance";
        PCIE_ASPM_ON_BAT = "powersave";

        SOUND_POWER_SAVE_ON_AC  = 0;
        SOUND_POWER_SAVE_ON_BAT = 1;

        CPU_BOOST_ON_BAT = 0;
        CPU_BOOST_ON_AC = 1;

        CPU_MAX_PERF_ON_BAT = 60;
        CPU_MAX_PERF_ON_AC = 100;

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
