{ config, pkgs, user, ... }:

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
in { 
  # Brightness Fix
  environment.systemPackages = with pkgs; [
    touchscreen-innhibit
  ];

  security.sudo.extraRules = [
    {
      users = [ user ];
      commands = [
        {
          command = "/run/current-system/sw/bin/touchscreen-innhibit"; 
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  # Hardware Settings
  hardware.graphics = {
    enable = true;
    enable32Bit = true; 
    extraPackages = with pkgs; [              
      rocmPackages.clr.icd 
    ];
  };

  zramSwap = {
    enable = true;
    memoryPercent = 50;
    algorithm = "zstd";
  };

  environment.etc."nbfc/nbfc.json".text = ''
    {
      "SelectedConfigId": "Honor MagicBook 14",
      "Models": [
        {
          "Name": "Honor MagicBook X14 Plus 2024",
          "FanConfigurations": [
            {
              "WriteRegister": 148,
              "ReadRegister": 148,
              "MinSpeedValue": 0,
              "MaxSpeedValue": 100,
              "TemperatureThresholds": [
                { "UpThreshold": 50, "DownThreshold": 45, "FanSpeed": 0 },
                { "UpThreshold": 60, "DownThreshold": 55, "FanSpeed": 30 },
                { "UpThreshold": 75, "DownThreshold": 70, "FanSpeed": 100 }
              ]
            }
          ]
        }
      ]
    }
  '';

  systemd.services.nbfc-linux = {
    description = "Notebook Fan Control service";
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.nbfc-linux ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.nbfc-linux}/bin/nbfc-linux --config-dir /etc/nbfc";
      Restart = "always";
    };
  };
}
