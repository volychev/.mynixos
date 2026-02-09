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

    sleep 0.5

    MAX_VAL=$($BC m)
    CUR_VAL=$($BC g)
    PERC=$(( CUR_VAL * 100 / MAX_VAL ))

    if [[ $(cat /sys/class/power_supply/AC*/online) -eq 1 ]]; then
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
  '';
in
{
  environment.systemPackages = with pkgs; [
    animateBrightness
  ];

  services.udev.extraRules = ''
    SUBSYSTEM=="power_supply", ACTION=="change", RUN+="${powerChangeScript}"
  '';

  powerManagement.powertop.enable = true;

  services.auto-cpufreq = {
    enable = true;
    settings = {
      battery = { 
        governor = "powersave"; 
        turbo = "never"; 
      };
      charger = { 
        governor = "performance"; 
        turbo = "auto"; 
      };
    };
  };

  services.ananicy = {
    enable = true;
    package = pkgs.ananicy-cpp;
    rulesProvider = pkgs.ananicy-rules-cachyos;
  };
}