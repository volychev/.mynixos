#!/bin/bash

MONITOR="eDP-1"

RES="auto"

RATE_AC="120"
RATE_BAT="60"

SCALE="1.8"

BRIGHT_AC="100%"
BRIGHT_BAT="60%"

BAT_PATH="/sys/class/power_supply/BATT/status"

current_mode=""

while true; do
    if [ -f "$BAT_PATH" ]; then
        STATUS=$(cat "$BAT_PATH")
    else
        STATUS="Unknown"
    fi

    if [ "$STATUS" = "Discharging" ]; then
        new_mode="bat"
    else
        new_mode="ac"
    fi

    if [ "$current_mode" != "$new_mode" ]; then
        if [ "$new_mode" = "bat" ]; then
            echo "Switching to BATTERY mode..."
            
            # 1. TDP (RyzenAdj) - 12W
            sudo ryzenadj --stapm-limit=12000 --fast-limit=12000 --slow-limit=12000 --tctl-temp=60
            
            # 2. Monitor (60Hz)
            hyprctl keyword monitor "$MONITOR, ${RES}@${RATE_BAT}, 0x0, $SCALE"
            
            # 3. Brightness
            brightnessctl set $BRIGHT_BAT
            
        else
            echo "Switching to PERFORMANCE mode..."
            
            # 1. TDP (RyzenAdj) - 45W/54W
            sudo ryzenadj --stapm-limit=45000 --fast-limit=54000 --slow-limit=65000 --tctl-temp=95
            
            # 2. Monitor (120Hz)
            hyprctl keyword monitor "$MONITOR, ${RES}@${RATE_AC}, 0x0, $SCALE"
            
            # 3. Brightness
            brightnessctl set $BRIGHT_AC
        fi
        current_mode="$new_mode"
    fi
    
    sleep 5
done
