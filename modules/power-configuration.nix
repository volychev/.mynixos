{ pkgs, ... }:

let
  animateBrightness = pkgs.writeShellScriptBin "animate-brightness" ''
    TARGET=$1
    
    if [ -z "$TARGET" ]; then
      echo "Usage: animate-brightness <target_percent>"
      exit 1
    fi

    BC="${pkgs.brightnessctl}/bin/brightnessctl"

    MAX=$($BC m)
    CURRENT=$($BC g)
    CURRENT_PCT=$(( CURRENT * 100 / MAX ))

    STEP=2       
    DELAY=0.0025

    if [ "$CURRENT_PCT" -eq "$TARGET" ]; then
      exit 0
    fi

    while [ "$CURRENT_PCT" -ne "$TARGET" ]; do
      if [ "$CURRENT_PCT" -lt "$TARGET" ]; then
        CURRENT_PCT=$((CURRENT_PCT + STEP))
        if [ "$CURRENT_PCT" -gt "$TARGET" ]; then CURRENT_PCT=$TARGET; fi
      else
        CURRENT_PCT=$((CURRENT_PCT - STEP))
        if [ "$CURRENT_PCT" -lt "$TARGET" ]; then CURRENT_PCT=$TARGET; fi
      fi
      
      $BC set "''${CURRENT_PCT}%" -q
      sleep $DELAY
    done
  '';


  batteryChangeScript = pkgs.writeShellScript "battery-change-script" ''
    POWER_PROFILE="${powerProfileScript}/bin/power-profile"
    PROFILE_FILE="/run/user/1000/power_profile_mode"
    LOG="/run/user/1000/battery-change.log"

    export XDG_RUNTIME_DIR=/run/user/1000
    export HYPRLAND_INSTANCE_SIGNATURE=$(ls /run/user/1000/hypr/ 2>/dev/null | head -1)
    export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus

    sleep 0.5

    BAT_LEVEL=$(cat /sys/class/power_supply/BATT/capacity 2>/dev/null || echo 100)
    AC_STATUS=$(cat /sys/class/power_supply/ACAD/online 2>/dev/null || echo 1)
    current=$(cat "$PROFILE_FILE" 2>/dev/null || echo "standard")

    echo "$(date): AC=$AC_STATUS BAT=$BAT_LEVEL current=$current" >> "$LOG"

    if [ "$AC_STATUS" = "1" ] && [ "$current" = "eco" ]; then
      echo "$(date): switching to standard" >> "$LOG"
      $POWER_PROFILE set standard >> "$LOG" 2>&1
    elif [ "$AC_STATUS" = "0" ] && [ "$BAT_LEVEL" -lt 20 ] && [ "$current" != "eco" ]; then
      echo "$(date): switching to eco" >> "$LOG"
      $POWER_PROFILE set eco >> "$LOG" 2>&1
    fi

    if [ "$AC_STATUS" = "0" ] && [ "$BAT_LEVEL" -le 3 ]; then
      systemctl suspend
    fi
  '';


  powerProfileScript = pkgs.writeShellScriptBin "power-profile" ''
    # Constants
    PROFILE_FILE="/run/user/1000/power_profile_mode"
    HYPRIDLE_SERVICE="hypridle.service"
    ANIMATE="${animateBrightness}/bin/animate-brightness"
    BC="${pkgs.brightnessctl}/bin/brightnessctl"
    PKILL="${pkgs.procps}/bin/pkill"
    HYPRCTL="${pkgs.hyprland}/bin/hyprctl"
    
    # Helpers
    get_profile() {
        if [ -f "$PROFILE_FILE" ]; then
            cat "$PROFILE_FILE"
        else
            echo "standard"
        fi
    }

    get_brightness_pct() {
        local max cur
        max=$($BC m)
        cur=$($BC g)
        echo $(( cur * 100 / max ))
    }
    
    set_profile() {
        local profile=$1
        echo "$(date): Setting profile to $profile" >> /run/user/1000/power-profile.log
        
        case "$profile" in
            "standard")
                # CPU: balance_performance EPP, boost on, no freq cap
                systemctl start "cpu-epp@balance_performance"
                systemctl start "cpu-boost@1"
                systemctl start "cpu-maxperf@100"
                systemctl --user stop $HYPRIDLE_SERVICE
                $HYPRCTL reload
                current_pct=$(get_brightness_pct)
                if [ "$current_pct" -lt 90 ]; then
                  $ANIMATE 90
                fi
                ;;
            "eco")
                # CPU: power EPP, boost off, 60% freq cap
                systemctl start "cpu-epp@power"
                systemctl start "cpu-boost@0"
                systemctl start "cpu-maxperf@35"
                systemctl --user start $HYPRIDLE_SERVICE
                $HYPRCTL keyword monitor "eDP-1, 2880x1800@60, auto, 1.8"
                current_pct=$(get_brightness_pct)
                if [ "$current_pct" -gt 50 ]; then
                  $ANIMATE 50
                fi
                # Visuals: no blur, opaque inactive windows, faster animations
                $HYPRCTL keyword decoration:blur:enabled false
                $HYPRCTL keyword decoration:inactive_opacity 1.0
                $HYPRCTL keyword animation "global,     1, 2.5,  default"
                $HYPRCTL keyword animation "windows,    1, 1.2,  easeOutQuint"
                $HYPRCTL keyword animation "windowsIn,  1, 1,    easeOutQuint, popin 87%"
                $HYPRCTL keyword animation "windowsOut, 1, 0.37, linear, popin 87%"
                $HYPRCTL keyword animation "fade,       1, 0.75, quick"
                $HYPRCTL keyword animation "layers,     1, 0.95, easeOutQuint"
                $HYPRCTL keyword animation "workspaces, 1, 0.5,  almostLinear, fade"
                ;;
            "performance")
                # CPU: performance EPP, boost on, no freq cap
                systemctl start "cpu-epp@performance"
                systemctl start "cpu-boost@1"
                systemctl start "cpu-maxperf@100"
                systemctl --user stop $HYPRIDLE_SERVICE
                $HYPRCTL reload
                current_pct=$(get_brightness_pct)
                if [ "$current_pct" -lt 100 ]; then
                  $ANIMATE 100
                fi
                ;;
        esac

        echo "$profile" > "$PROFILE_FILE"
        chmod 0644 "$PROFILE_FILE" 2>/dev/null || true
        
        # Update Waybar (signal 42 = SIGRTMIN+8)
        WAYBAR_PID=$(${pkgs.procps}/bin/pgrep -f "waybar" | head -1)
        [ -n "$WAYBAR_PID" ] && kill -42 "$WAYBAR_PID" 2>/dev/null || true
    }
    
    cycle_profile() {
        local current=$(get_profile)
        case "$current" in
            "standard") set_profile "eco" ;;
            "eco") set_profile "performance" ;;
            "performance") set_profile "standard" ;;
            *) set_profile "standard" ;;
        esac
    }

    toggle_eco_standard() {
        local current=$(get_profile)
        case "$current" in
            "eco") set_profile "standard" ;;
            *) set_profile "eco" ;;
        esac
    }

    toggle_perf_standard() {
        local current=$(get_profile)
        case "$current" in
            "performance") set_profile "standard" ;;
            *) set_profile "performance" ;;
        esac
    }

    get_waybar_json() {
        local current=$(get_profile)
        local text=""
        local tooltip=""
        local class="$current"
        
        case "$current" in
            "standard") text="std::~" tooltip="Standard Mode" ;;
            "eco") text="eco::*" tooltip="Eco Mode" ;;
            "performance") text="prf::^" tooltip="Performance Mode" ;;
        esac
        
        echo "{\"text\": \"$text\", \"tooltip\": \"$tooltip\", \"class\": \"$class\", \"alt\": \"$class\"}"
    }

    case "$1" in
        "get") get_waybar_json ;;
        "set") set_profile "$2" ;;
        "next") cycle_profile ;;
        "toggle-eco") toggle_eco_standard ;;
        "toggle-performance") toggle_perf_standard ;;
        "init") set_profile "standard" ;;
        *) echo "Usage: $0 {get|set <mode>|next|toggle-eco|toggle-performance|init}" ;;
    esac
  '';

in
{
  environment.systemPackages = with pkgs; [
    animateBrightness
    powerProfileScript
  ];

  # Системные сервисы для записи EPP и boost в sysfs (запускаются через polkit без пароля)
  systemd.services."cpu-epp@" = {
    description = "Set CPU energy_performance_preference to %i";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.writeShellScript "set-cpu-epp" ''
        epp="$1"
        for f in /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference; do
          echo "$epp" > "$f"
        done
      ''} %i";
    };
  };

  systemd.services."cpu-boost@" = {
    description = "Set CPU boost to %i";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.writeShellScript "set-cpu-boost" ''
        boost="$1"
        if [ -f /sys/devices/system/cpu/cpufreq/boost ]; then
          echo "$boost" > /sys/devices/system/cpu/cpufreq/boost
        fi
      ''} %i";
    };
  };

  systemd.services."cpu-maxperf@" = {
    description = "Set CPU max performance to %i%%";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.writeShellScript "set-cpu-maxperf" ''
        pct="$1"
        for policy in /sys/devices/system/cpu/cpufreq/policy*; do
          max_freq=$(cat "$policy/cpuinfo_max_freq")
          target=$(( max_freq * pct / 100 ))
          echo "$target" > "$policy/scaling_max_freq"
        done
      ''} %i";
    };
  };

  # Polkit: пользователи группы wheel могут запускать cpu-epp@, cpu-boost@, cpu-maxperf@ без пароля
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id === "org.freedesktop.systemd1.manage-units" &&
          /^cpu-(epp|boost|maxperf)@/.test(action.lookup("unit")) &&
          subject.isInGroup("wheel")) {
        return polkit.Result.YES;
      }
    });
  '';

  powerManagement.powertop.enable = false;
  systemd.services.iio-sensor-proxy.enable = false;

  services = {
    power-profiles-daemon.enable = false;
    udev.extraRules = ''
      SUBSYSTEM=="power_supply", ACTION=="change", RUN+="${batteryChangeScript}"
      ACTION=="add|change", KERNEL=="nvme*", ATTR{queue/scheduler}="none"
      ACTION=="add|change", SUBSYSTEM=="power_supply", ATTR{charge_control_end_threshold}="100"
      ACTION=="add|change", SUBSYSTEM=="power_supply", ATTR{charge_stop_threshold}="100"
    '';
    tlp = {
      enable = true;
      settings = {
        # CPU governor (amd_pstate работает с powersave + EPP)
        CPU_SCALING_GOVERNOR_ON_AC  = "powersave";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
        # EPP и boost — пустая строка = TLP не трогает, управляет наш скрипт
        CPU_ENERGY_PERF_POLICY_ON_AC  = "";
        CPU_ENERGY_PERF_POLICY_ON_BAT = "";
        CPU_BOOST_ON_AC  = "";
        CPU_BOOST_ON_BAT = "";

        # Wi-Fi: power save на батарее, выкл на зарядке
        WIFI_PWR_ON_AC  = "off";
        WIFI_PWR_ON_BAT = "on";

        # USB autosuspend — устройства засыпают когда не используются
        USB_AUTOSUSPEND = 1;

        # PCI Express ASPM — агрессивный на батарее
        PCIE_ASPM_ON_AC  = "default";
        PCIE_ASPM_ON_BAT = "powersupersave";

        # Runtime PM для PCI устройств
        RUNTIME_PM_ON_AC  = "on";
        RUNTIME_PM_ON_BAT = "auto";

        # Звуковая карта: power save на батарее
        SOUND_POWER_SAVE_ON_AC  = 0;
        SOUND_POWER_SAVE_ON_BAT = 1;

        # NVMe: APST (автоматическое управление мощностью)
        AHCI_RUNTIME_PM_ON_AC  = "on";
        AHCI_RUNTIME_PM_ON_BAT = "auto";
      };
    };
    ananicy = {
      enable = true;
      package = pkgs.ananicy-cpp;
      rulesProvider = pkgs.ananicy-rules-cachyos;
    };
  };
}
