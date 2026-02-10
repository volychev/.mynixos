{ config, pkgs, ... }:

{
  programs.waybar = {
    enable = true;
    
    systemd.enable = true;

    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        reload_style_on_change = true;

        modules-left = [ "group/workspace" "idle_inhibitor" "group/windowtray" ];
        modules-center = [ "custom/clock" ];
        modules-right = [ "hyprland/language" "group/connections" "group/stats" ];

        "group/workspace" = {
          orientation = "horizontal";
          modules = [ "hyprland/workspaces" ];
        };

        "group/windowtray" = {
          orientation = "horizontal";
          modules = [ "group/expand" "hyprland/window" ];
        };

        "group/connections" = {
          orientation = "horizontal";
          # VPN перемещен сразу слева от network
          modules = [ "bluetooth" "custom/vpn" "network" ];
        };

        "group/stats" = {
          orientation = "horizontal";
          modules = [ "pulseaudio" "backlight" "battery" ];
        };

        "hyprland/workspaces" = {
          "format" = "{name}"; 
          persistent-workspaces = {
            "*" = [ 1 2 ];
          };
        };

        "hyprland/window" = {
          format = "{title}";
          max-length = 40;
          rewrite = {
            "^$" = "...";
          };
        };

        "hyprland/language" = {
          format = "{short}";
          on-click = "hyprctl switchxkblayout all next";
        };

        "custom/expand" = {
          format = "#";
          interval = 1;
          tooltip = false;
        };

        "group/expand" = {
          orientation = "horizontal";
          drawer = {
            transition-duration = 300;
            transition-to-left = false;
            click-to-reveal = true;
          };
          modules = [ "custom/expand" "tray" ];
        };

        tray = {
          icon-size = 13;
          spacing = 10;
        };

        "custom/clock" = {
          format = "{}";
          exec = "date '+%b %d, %H:%M' | tr '[:upper:]' '[:lower:]'";
          interval = 1;
          tooltip = false;
        };

        "custom/vpn" = {
            format = "vpn::{}";
            exec = "ip link show throne-tun | grep -q '<.*UP.*>' && echo '@' || echo 'X'";
            on-click = "Throne"; 
            interval = 3;
            tooltip = false;
        };

        network = {
          format-wifi = "wlan::{signalStrength}";
          format-ethernet = "eth::@";
          format-disconnected = "net::X";
          on-click = "kitty nmtui";
        };

        bluetooth = {
          format-on = "bth::#";
          format-off = "bth::X";
          format-connected = "bth::@";
          format-disabled = "bth::X";
          on-click = "blueman-manager";
          on-click-right = "rfkill toggle bluetooth";
        };

        pulseaudio = {
          format = "snd::{volume}";
          format-bluetooth = "snd@bth::{volume}";
          format-muted = "snd::X";
          format-source = "mic::{volume}";
          format-source-muted = "mic::X";
          on-scroll-up = "pamixer -d 1";
          on-scroll-down = "pamixer -i 1";
          on-click = "pamixer --toggle-mute";
          on-click-right = "pavucontrol";
        };

        backlight = {
          device = "amdgpu_bl1"; 
          format = "scr::{percent}";
          on-scroll-up = "brightnessctl set 1%-";
          on-scroll-down = "brightnessctl set 1%+";
          on-click = "swaync-client -t -sw";
        };

        battery = {
          interval = 30;
          format = "pwr::{capacity}";
          format-charging = "pwr::^{capacity}%";
          format-plugged = "ac::{capacity}%";
          states = {
            warning = 30;
            critical = 15;
          };
        };

        idle_inhibitor = {
          format = "{icon}";
          format-icons = {
            activated = "idl::(O_O)";
            deactivated = "idl::(-_-)";
          };
          tooltip = true;
        };
      };
    };

    style = ''
      @define-color foreground #e6e6e7;
      @define-color background #0c0c0c;
      @define-color cursor #e6e6e7;

      @define-color color0 #0c0c0c;
      @define-color color1 #7F8082;
      @define-color color2 #8E8E8F;
      @define-color color3 #9F9FA0;
      @define-color color4 #AEAEAE;
      @define-color color5 #BFBFC0;
      @define-color color6 #CECECE;
      @define-color color7 #e6e6e7;
      @define-color color8 #a1a1a1;
      @define-color color9 #7F8082;
      @define-color color10 #8E8E8F;
      @define-color color11 #9F9FA0;
      @define-color color12 #AEAEAE;
      @define-color color13 #BFBFC0;
      @define-color color14 #CECECE;
      @define-color color15 #e6e6e7;

      * {
          font-size: 12px;
          font-family: "JetBrainsMono Nerd Font", monospace;
          font-weight: bold;
          letter-spacing: -0.5px;
      }
      
      window#waybar {
          all: unset;
      }

      .modules-left, .modules-center, .modules-right {
          background: transparent;
          padding: 0;
          margin: 0;
      }

      .modules-left {
          margin: 5px 0 0 5px;
      }

      .modules-center {
          margin-top: 5px;
      }

      .modules-right {
          margin: 5px 5px 0 0;
      }

      #workspace {
          background: alpha(@background, 0.5);
          padding: 7px;
          border-radius: 10px;
          margin-right: 5px;
      }

      #idle_inhibitor {
          background: alpha(@background, 0.5);
          padding: 7px 10px;
          border-radius: 10px;
          margin-right: 5px;
          color: @color7;
      }

      #windowtray {
          background: alpha(@background, 0.5);
          padding: 7px;
          border-radius: 10px;
      }

      #custom-clock {
          background: alpha(@background, 0.5);
          padding: 7px 15px;
          border-radius: 10px;
          color: @color7;
          font-size: 12px;
      }

      #connections {
          background: alpha(@background, 0.5);
          padding: 7px;
          border-radius: 10px;
          margin-right: 5px;
      }

      #stats {
          background: alpha(@background, 0.5);
          padding: 7px;
          border-radius: 10px;
      }

      #language {
          background: alpha(@background, 0.5);
          padding: 7px 10px;
          border-radius: 10px;
          margin-right: 5px;
          color: @color7;
      }

      #window {
          padding-left: 5px;
          padding-right: 10px;
          color: @color7;
          font-weight: normal;
      }

      #workspaces button {
          all: unset;
          padding: 0px 5px;
          color: @color9;
          transition: all .2s ease;
      }

      #workspaces button:hover {
          color: rgba(0, 0, 0, 0);
      }

      #workspaces button.active {
          color: @color7;
      }

      #network, #bluetooth, #pulseaudio, #backlight, #battery, #custom-vpn {
          padding: 0 6px;
          color: @color7;
      }

      #battery.charging {
          color: #26A65B;
      }

      #battery.warning:not(.charging) {
          color: #ffbe61;
      }

      #battery.critical:not(.charging) {
          color: #f53c3c;
          animation: blink 0.5s infinite alternate;
      }

      #custom-expand {
          padding: 0 5px;
          color: @color7;
          margin-left: 5px;
      }

      #tray {
          padding: 0 5px;
      }

      tooltip {
          background: @background;
          color: @color7;
      }

      #custom-clock:hover,
      #connections:hover,
      #stats:hover,
      #workspace:hover,
      #windowtray:hover,
      #language:hover,
      #idle_inhibitor:hover {
          transition: all 0.3s ease;
      }
    '';
  };
}