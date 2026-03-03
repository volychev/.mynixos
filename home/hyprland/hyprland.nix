{ config, pkgs, inputs, ... }:

let
  touchscreen-innhibit = pkgs.writeShellScriptBin "touchscreen-innhibit" ''
    find_touch_device() {
        local input_devices_file="/proc/bus/input/devices"
        local device_name="GXTP7863"
        local unknown_marker="UNKNOWN"
        
        while IFS= read -r line; do
            if [[ $line == N:*"$device_name"* && $line == *"$unknown_marker"* ]]; then
                local in_device_block=1
                local sysfs_path=""
                
                while IFS= read -r device_line && [[ $in_device_block -eq 1 ]]; do
                    if [[ -z $device_line ]]; then
                        in_device_block=0
                    elif [[ $device_line == S:* ]]; then
                        sysfs_path=''${device_line#S: Sysfs=}
                    fi
                done
                
                if [[ -n $sysfs_path ]]; then
                    echo "$sysfs_path"
                    return 0
                fi
            fi
        done < "$input_devices_file"
        
        return 1
    }
    
    sysfs_path=$(find_touch_device)
    
    if [[ -z $sysfs_path ]]; then
        exit 1
    fi
    
    inhibit_path="/sys''${sysfs_path}/inhibited"
    
    if [[ ! -f $inhibit_path ]]; then
        alternative_path=$(echo "$inhibit_path" | sed 's/\.000[0-9]\+/.0001/')
        
        if [[ -f "$alternative_path" ]]; then
            inhibit_path="$alternative_path"
        else
            exit 1
        fi
    fi
  
    echo 1 > "$inhibit_path"
    
    if [[ $? -eq 0 ]]; then
        echo "Touchscreen locked."
    else
        exit 1
    fi
  '';
  
  toggle-cinema = pkgs.writeShellScriptBin "toggle-cinema" ''
      HYPRCTL="${pkgs.hyprland}/bin/hyprctl"
      WAYBAR="${pkgs.waybar}/bin/waybar"
      PKILL="${pkgs.procps}/bin/pkill"
      PGREP="${pkgs.procps}/bin/pgrep"

      if $PGREP -f "waybar" > /dev/null; then
          $PKILL waybar

          $HYPRCTL keyword workspace "w[tv1], gapsout:0, gapsin:0, border:false, rounding:false, decorate:false"
          $HYPRCTL keyword windowrule "match:workspace w[tv1], match:float false, border_size 0"
          $HYPRCTL keyword keyword windowrule "match:workspace w[tv1], match:float false, no_anim true"
      else
          $HYPRCTL reload
          $WAYBAR &
      fi
  '';

  state-file = "/tmp/hyprexpo.active";
  waybar-restore-file = "/tmp/waybar.should_restore";

  expo-watcher = pkgs.writeShellScriptBin "expo-watcher" ''
    HYPRCTL="${pkgs.hyprland}/bin/hyprctl"
    WAYBAR="${pkgs.waybar}/bin/waybar"

    ${pkgs.socat}/bin/socat -U - UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock | while read -r line; do
      if [[ "$line" == "workspace>>"* ]]; then
        rm -f "${state-file}"
        pkill -P $$
        exit 0
      fi
    done
  '';

  gesture-up = pkgs.writeShellScriptBin "gesture-up" ''
    PGREP="${pkgs.procps}/bin/pgrep"
    PKILL="${pkgs.procps}/bin/pkill"

    if pgrep -x rofi > /dev/null; then
      pkill rofi
      exit 0
    fi

    if [ -f "${state-file}" ]; then
      exit 0
    fi

    touch "${state-file}"
    hyprctl dispatch hyprexpo:expo
    expo-watcher &
  '';

  gesture-down = pkgs.writeShellScriptBin "gesture-down" ''
    if [ -f "${state-file}" ]; then
      hyprctl dispatch workspace e+1
    else
      rofi-launcher
    fi
  '';
in
{
  home.packages = with pkgs; [
    touchscreen-innhibit
    toggle-cinema
    expo-watcher
    gesture-up
    gesture-down
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    
    package = inputs.hyprland.packages.${pkgs.system}.hyprland;
    
    plugins = [
      inputs.hyprland-plugins.packages.${pkgs.system}.hyprexpo
    ];

    settings = {
      "plugin:hyprexpo" = {
        columns = 3;             
        gap_size = 20;           
        bg_col = "rgb(000000)";  

        workspace_method = "center current"; 
      };

      "$terminal" = "kitty";
      "$fileManager" = "nemo";
      "$menu" = "rofi-launcher";
      "$clipboard" = "rofi-clipboard";
      "$screenshot" = "grim -g \"$(slurp -b 00000066 -c 00000000 -B BFb4faff -w 2)\" - | tee >(wl-copy) | swappy -f -";
      "$vpn" = "Throne";
      "$telegram" = "Telegram";
      "$browser" = "zen-beta";
      "$mainMod" = "SUPER";

      ################
      ### MONITORS ###
      ################
      "monitor" = ",preferred,auto,1.8";

      ###################
      ### ENVIRONMENT ###
      ###################
      env = [
        "XDG_CURRENT_DESKTOP,Hyprland"
        "XDG_SESSION_TYPE,wayland"
        "XDG_SESSION_DESKTOP,Hyprland"
        "QT_AUTO_SCREEN_SCALE_FACTOR,1"
        "QT_QPA_PLATFORM,wayland;xcb"
        "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"
        "QT_QPA_PLATFORMTHEME,qt5ct"
        "SDL_VIDEODRIVER,wayland"
        "LANG,en_US.UTF-8"
        "LC_ALL,en_US.UTF-8"
        "XCURSOR_SIZE,18"
        "HYPRCURSOR_SIZE,18"
        "WLR_DRM_NO_ATOMIC,1"
        "MOZ_ENABLE_WAYLAND,1"
      ];

      #################
      ### AUTOSTART ###
      #################
      "exec-once" = [
        "$terminal"
        "sudo touchscreen-innhibit"
        "udiskie --smarttray &"
        "wl-paste --type text --watch cliphist store"
        "wl-paste --type image --watch cliphist store"
        "$vpn"
      ];

      ################
      ### XWAYLAND ###
      ################
      "xwayland" = {
        "force_zero_scaling" = true;
      };

      #############
      ### INPUT ###
      #############
      "input" = {
        "kb_layout" = "us,ru";
        "kb_variant" = "";
        "kb_model" = "";
        "kb_options" = "grp:alt_shift_toggle";
        "kb_rules" = "";

        "follow_mouse" = 1;
        "sensitivity" = 0;

        "touchpad" = {
          "natural_scroll" = true;
        };
      };

      #####################
      ### LOOK AND FEEL ###
      #####################
      "general" = {
        "gaps_in" = 5;
        "gaps_out" = 5;
        "border_size" = 0;
        "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
        "col.inactive_border" = "rgba(595959aa)";
        "resize_on_border" = true;
        "allow_tearing" = false;
        "layout" = "dwindle";
      };

      "decoration" = {
        "rounding" = 10;
        "rounding_power" = 2.0;
        "active_opacity" = 1.0;
        "inactive_opacity" = 0.9;
        
        "blur" = {
            "enabled" = true;
            "size" = 10;
            "passes" = 2;
            "brightness" = 1.1;
            "contrast" = 1.0;
            "noise" = 0.01;
            "new_optimizations" = true;
            "popups" = false;
        };
      };

      "animations" = {
        "enabled" = true;

        "bezier" = [
          "easeOutQuint,   0.23, 1,    0.32, 1"
          "easeInOutCubic, 0.65, 0.05, 0.36, 1"
          "linear,         0,    0,    1,    1"
          "almostLinear,   0.5,  0.5,  0.75, 1"
          "quick,          0.15, 0,    0.1,  1"
        ];

        "animation" = [
          "global,        1,     10,    default"
          "border,        1,     5.39,  easeOutQuint"
          "windows,       1,     4.79,  easeOutQuint"
          "windowsIn,     1,     4.1,   easeOutQuint, popin 87%"
          "windowsOut,    1,     1.49,  linear,       popin 87%"
          "fadeIn,        1,     1.73,  almostLinear"
          "fadeOut,       1,     1.46,  almostLinear"
          "fade,          1,     3.03,  quick"
          "layers,        1,     3.81,  easeOutQuint"
          "layersIn,      1,     4,     easeOutQuint, fade"
          "layersOut,     1,     1.5,   linear,       fade"
          "fadeLayersIn,  1,     1.79,  almostLinear"
          "fadeLayersOut, 1,     1.39,  almostLinear"
          "workspaces,    1,     1.94,  almostLinear, fade"
          "workspacesIn,  1,     1.21,  almostLinear, fade"
          "workspacesOut, 1,     1.94,  almostLinear, fade"
          "zoomFactor,    1,     7,     quick"
        ];
      };

      "dwindle" = {
        "pseudotile" = true;
        "preserve_split" = true;
      };

      "master" = {
        "new_status" = "slave";
      };

      "misc" = {
        "force_default_wallpaper" = 0;
        "disable_hyprland_logo" = true;
        "vfr" = true;
        "vrr" = 0;
        "on_focus_under_fullscreen" = 0;
      };

      ################
      ### GESTURES ###
      ################
      "gestures" = {
        "workspace_swipe_distance" = 700;
        "workspace_swipe_cancel_ratio" = 0;
        "workspace_swipe_direction_lock" = false;
        "workspace_swipe_forever" = true;
      };

      "gesture" = [
        "3, horizontal, workspace"
        "3, down, dispatcher, exec, gesture-down"
        "3, up, dispatcher, exec, gesture-up"
        "4, up, dispatcher, exec, toggle-cinema"
        "4, down, dispatcher, exec, toggle-cinema"
      ];

      ############################
      ### WINDOWS & WORKSPACES ###
      ############################
      "windowrule" = [
        "match:class .*, suppress_event maximize"
        "no_focus on, match:class ^$, match:title ^$, match:xwayland 1, match:float 1, match:fullscreen 0, match:pin 0"
      ];

      ###################
      ### KEYBINDINGS ###
      ###################
      "bind" = [
        "$mainMod, SPACE, exec, $terminal"
        "$mainMod, X, killactive,"
        "$mainMod, F, exec, $fileManager"
        "$mainMod, V, exec, $clipboard"
        "$mainMod, R, exec, $menu"
        "$mainMod, Grave, exec, $vpn"
        "$mainMod, T, exec, $telegram"
        "$mainMod, Z, exec, $browser"
        "$mainMod SHIFT, S, exec, $screenshot"
        "$mainMod, Tab, exec, gesture-up"
        
        # Workspaces
        "$mainMod, 1, workspace, 1"
        "$mainMod, 2, workspace, 2"
        "$mainMod, 3, workspace, 3"
        "$mainMod, 4, workspace, 4"
        "$mainMod, 5, workspace, 5"
        "$mainMod, 6, workspace, 6"
        "$mainMod, 7, workspace, 7"
        "$mainMod, 8, workspace, 8"
        "$mainMod, 9, workspace, 9"
        "$mainMod, 0, workspace, 10"

        # Move to workspace
        "$mainMod SHIFT, 1, movetoworkspace, 1"
        "$mainMod SHIFT, 2, movetoworkspace, 2"
        "$mainMod SHIFT, 3, movetoworkspace, 3"
        "$mainMod SHIFT, 4, movetoworkspace, 4"
        "$mainMod SHIFT, 5, movetoworkspace, 5"
        "$mainMod SHIFT, 6, movetoworkspace, 6"
        "$mainMod SHIFT, 7, movetoworkspace, 7"
        "$mainMod SHIFT, 8, movetoworkspace, 8"
        "$mainMod SHIFT, 9, movetoworkspace, 9"
        "$mainMod SHIFT, 0, movetoworkspace, 10"

        "$mainMod, mouse_down, workspace, e+1"
        "$mainMod, mouse_up, workspace, e-1"
      ];

      "bindm" = [
        "$mainMod, mouse:272, movewindow"
        "$mainMod + ALT, mouse:272, resizewindow"
      ];

      "bindel" = [
        ",XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 1%+"
        ",XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%-"
        ",XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ",XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
        ",XF86MonBrightnessUp, exec, brightnessctl -e4 -n2 set 1%+"
        ",XF86MonBrightnessDown, exec, brightnessctl -e4 -n2 set 1%-"
      ];

      "bindl" = [
        ", XF86AudioNext, exec, playerctl next"
        ", XF86AudioPause, exec, playerctl play-pause"
        ", XF86AudioPlay, exec, playerctl play-pause"
        ", XF86AudioPrev, exec, playerctl previous"
      ];

      extraConfig = ''
        layerrule = blur on, match:namespace ^(rofi)$
        layerrule = ignore_alpha 0, match:namespace ^(rofi)$
        layerrule = blur on, match:namespace ^(rofi)$
        layerrule = ignore_alpha 0, match:namespace ^(rofi)$

        layerrule = blur on, match:namespace ^(waybar)$
        layerrule = ignore_alpha 0, match:namespace ^(waybar)$
        
        layerrule = no_anim on, match:namespace ^(hyprpicker)$
        layerrule = no_anim on, match:namespace ^(selection)$
      '';
    };
  };  
}