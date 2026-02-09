{ pkgs, ... }:

let
  animBin = "animate-brightness"; 
  
  idleHandler = pkgs.writeShellScript "hypridle-handler" ''
    action="$1"
    cache_file="/tmp/hypridle_brightness_restore"
    
    BC="${pkgs.brightnessctl}/bin/brightnessctl"
    
    get_perc() {
      max=$($BC m)
      cur=$($BC g)
      echo $(( cur * 100 / max ))
    }

    case "$action" in
      timeout)
        current=$(get_perc)
        
        echo "$current" > "$cache_file"
        
        if [ "$current" -gt 10 ]; then
          ${animBin} 10
        fi
        ;;
        
      resume)
        if [ -f "$cache_file" ]; then
          target=$(cat "$cache_file")
          ${animBin} "$target"
        fi
        ;;
    esac
  '';
in
{
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        after_sleep_cmd = "hyprctl dispatch dpms on";
        # Блокировку экрана лучше добавлять сюда (lock_cmd), если нужно
      };

      listener = [
        {
          timeout = 300;
          on-timeout = "${idleHandler} timeout";
          on-resume = "${idleHandler} resume";
        }
        {
          timeout = 360;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
        {
          timeout = 600;
          on-timeout = "systemctl suspend";
        }
      ];
    };
  };
}