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

  powerChangeScript = pkgs.writeShellScript "power-change-script" ''
    BC="${pkgs.brightnessctl}/bin/brightnessctl"
    HYPRCTL="${pkgs.hyprland}/bin/hyprctl"
    ANIMATE="${animateBrightness}/bin/animate-brightness"
    STATE_FILE="/tmp/power_state"

    sleep 0.5

    CURRENT_AC_STATUS=$(cat /sys/class/power_supply/AC*/online)

    if [ -f "$STATE_FILE" ]; then
        LAST_AC_STATUS=$(cat "$STATE_FILE")
    else
        LAST_AC_STATUS="unknown"
    fi

    if [ "$CURRENT_AC_STATUS" = "$LAST_AC_STATUS" ]; then
        exit 0
    fi

    echo "$CURRENT_AC_STATUS" > "$STATE_FILE"

    MAX_VAL=$($BC m)
    CUR_VAL=$($BC g)
    PERC=$(( CUR_VAL * 100 / MAX_VAL ))

    if [ "$CURRENT_AC_STATUS" -eq 1 ]; then
      $HYPRCTL keyword monitor "eDP-1, auto@120, auto, 1.8"

      if [ "$PERC" -lt 90 ]; then
        $ANIMATE 90 &
      fi
    else
      $HYPRCTL keyword monitor "eDP-1, auto@60, auto, 1.8"

      if [ "$PERC" -gt 50 ]; then
        $ANIMATE 50 &
      fi
    fi

    BAT_LEVEL=$(cat /sys/class/power_supply/BAT*/capacity | head -n 1)

    if [ "$BAT_LEVEL" -lt 5 ]; then
      if [ "$PERC" -gt 10 ]; then
        $ANIMATE 10 &
      fi
    fi

    if [ "$CURRENT_AC_STATUS" -eq 0 ] && [ "$BAT_LEVEL" -le 3 ]; then
        rm -f "$STATE_FILE"
        systemctl suspend
    fi
  '';
in
{
  environment.systemPackages = with pkgs; [
    animateBrightness
  ];

  powerManagement.powertop.enable = true;
  systemd.services.iio-sensor-proxy.enable = false;

  services = {
    power-profiles-daemon.enable = false;
    udev.extraRules = ''
      SUBSYSTEM=="power_supply", ACTION=="change", RUN+="${powerChangeScript}"
      ACTION=="add|change", KERNEL=="nvme*", ATTR{queue/scheduler}="none"
    '';
    auto-cpufreq = {
      enable = true;
      settings = {
        battery = { 
          governor = "powersave"; 
          turbo = "never"; 
          energy_performance_preference = "power";
        };
        charger = { 
          governor = "performance"; 
          turbo = "auto"; 
          energy_performance_preference = "balance_performance";
        };
      };
    };
    ananicy = {
      enable = true;
      package = pkgs.ananicy-cpp;
      rulesProvider = pkgs.ananicy-rules-cachyos;
    };
  };
}