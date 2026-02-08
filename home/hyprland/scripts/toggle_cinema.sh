#!/bin/bash

if pgrep -f "waybar" > /dev/null; then
    pkill waybar
    
    hyprctl keyword workspace "w[tv1], gaps_out:0, gaps_in:0, border:0, rounding:0"
    hyprctl keyword windowrule "match:float 0, match:workspace w[tv1], border_size 0"
    hyprctl keyword windowrule "match:float 0, match:workspace w[tv1], no_anim on"
else
    hyprctl reload
    waybar &
fi