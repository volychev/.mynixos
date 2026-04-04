{ config, pkgs, inputs, lib, ... }:
let
  mmsg-scroll = pkgs.writeShellScriptBin "mmsg-scroll" ''
    OUTPUT=$(mmsg -g -l | tr -d '[:space:]')

    LAST_CHAR=''${OUTPUT: -1}

    if [ "$LAST_CHAR" = "S" ]; then
        if [ "$1" = "up" ]; then
            mmsg -d focusstack,next
        elif [ "$1" = "down" ]; then
            mmsg -d focusstack,prev
        fi
    else
        mmsg -d toggleoverview
    fi
  '';

  mmsg-layout-switch = pkgs.writeShellScriptBin "mmsg-layout-switch" ''
    OUTPUT=$(mmsg -g -l | tr -d '[:space:]')

    LAST_CHAR=''${OUTPUT: -1}

    if [ "$LAST_CHAR" = "S" ]; then
        mmsg -l T
    else
        mmsg -l VS
    fi
  '';

  ags-interactive-center = pkgs.writeShellScriptBin "ags-interactive-center" ''
    MODE="$1"
    if [ -z "$MODE" ]; then
      exit 1
    fi

    ags request --instance ags interactive-center "$MODE"
  '';

  screenshot = pkgs.writeShellScriptBin "screenshot" ''
    SLURP_ARGS="-b 00000066 -c 00000000 -B BFb4faff -w 2"
    TEMP_IMG="/tmp/screenshot_$(date +%s).png"
    GEOM=$(slurp $SLURP_ARGS)

    if [ -z "$GEOM" ]; then
        exit 0
    fi

    if grim -g "$GEOM" "$TEMP_IMG"; then
        wl-copy --type image/png < "$TEMP_IMG"
        swappy -f "$TEMP_IMG" && rm "$TEMP_IMG"
    else
        exit 1
    fi
  '';

  screenshot-ocr = pkgs.writeShellScriptBin "screenshot-ocr" ''
        SLURP_ARGS="-b 00000066 -c 00000000 -B BFb4faff -w 2"
        TEMP_IMG="/tmp/ocr_$(date +%s).png"

        GEOM=$(slurp $SLURP_ARGS)
        if [ -z "$GEOM" ]; then exit 0; fi

        if grim -g "$GEOM" "$TEMP_IMG"; then
            TEXT=$(tesseract "$TEMP_IMG" - -l rus+eng 2>/dev/null)
            rm "$TEMP_IMG"

            NEW_TEXT=$(zenity --text-info \
                --title="OCR Result" \
                --width=600 \
                --height=400 \
                --editable \
                --ok-label="Copy to Clipboard" \
                --cancel-label="Cancel" <<< "$TEXT")

            if [ $? -eq 0 ]; then
                printf "%s" "$NEW_TEXT" | wl-copy
            fi
        else
            exit 1
        fi
    '';

  animate-brightness = pkgs.writeShellScriptBin "animate-brightness" ''
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

  power-mode = pkgs.writeShellScriptBin "power-mode" ''
    set -euo pipefail

    STATE_DIR="''${XDG_STATE_HOME:-$HOME/.local/state}/power-mode"
    CURRENT_FILE="$STATE_DIR/current"
    mkdir -p "$STATE_DIR"

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

    mode_icon() {
      case "$1" in
        ultra-eco) echo "􁇌" ;;
        eco) echo "􁂬" ;;
        balanced) echo "􁁔" ;;
        performance) echo "􀋧" ;;
      esac
    }

    mode_label() {
      case "$1" in
        ultra-eco) echo "Ultra-Eco" ;;
        eco) echo "Eco" ;;
        balanced) echo "Balanced" ;;
        performance) echo "Performance" ;;
      esac
    }

    get_mode() {
      if [ -f "$CURRENT_FILE" ]; then
        local saved
        saved="$(tr -d '[:space:]' < "$CURRENT_FILE")"
        if normalize_mode "$saved" >/dev/null 2>&1; then
          normalize_mode "$saved"
          return 0
        fi
      fi

      echo "balanced"
    }

    save_mode() {
      printf '%s\n' "$1" > "$CURRENT_FILE"
    }

    ac_online() {
      for supply in /sys/class/power_supply/*; do
        [ -d "$supply" ] || continue
        if [ "$(cat "$supply/type" 2>/dev/null || true)" = "Mains" ]; then
          if [ "$(cat "$supply/online" 2>/dev/null || echo 0)" = "1" ]; then
            echo "1"
            return 0
          fi
        fi
      done

      echo "0"
    }

    battery_percent() {
      for supply in /sys/class/power_supply/*; do
        [ -d "$supply" ] || continue
        if [ "$(cat "$supply/type" 2>/dev/null || true)" = "Battery" ] && [ -r "$supply/capacity" ]; then
          cat "$supply/capacity"
          return 0
        fi
      done

      return 1
    }

    can_enable_performance() {
      if [ "$(ac_online)" = "1" ]; then
        return 0
      fi

      local percent
      if percent="$(battery_percent 2>/dev/null)"; then
        if [ "$percent" -lt 30 ]; then
          return 1
        fi
      fi

      return 0
    }

    resolve_output_and_mode() {
      local preferred_output="$1"
      local target_hz="$2"

      python3 - "$preferred_output" "$target_hz" <<'PY'
import json
import math
import subprocess
import sys

preferred_output = sys.argv[1]
target_hz = float(sys.argv[2])
data = json.loads(subprocess.check_output(["wlr-randr", "--json"], text=True))

def enabled_outputs():
    return [item for item in data if item.get("enabled")]

enabled = enabled_outputs()
if not enabled:
    sys.exit(1)

output = None
for item in enabled:
    if item.get("name") == preferred_output:
        output = item
        break
if output is None:
    output = enabled[0]

modes = output.get("modes", [])
if not modes:
    sys.exit(1)

current = next((mode for mode in modes if mode.get("current")), modes[0])
same_resolution = [
    mode
    for mode in modes
    if mode.get("width") == current.get("width") and mode.get("height") == current.get("height")
]
candidates = same_resolution if same_resolution else modes
best = min(candidates, key=lambda mode: abs(float(mode.get("refresh", 0.0)) - target_hz))

width = int(best.get("width"))
height = int(best.get("height"))
refresh = float(best.get("refresh", target_hz))

print(output.get("name", ""))
print(f"{width}x{height}@{refresh:.6f}")
PY
    }

    apply_refresh() {
      local target_hz="$1"
      local preferred_output
      local output_name
      local mode_spec

      if ! command -v wlr-randr >/dev/null 2>&1; then
        echo "wlr-randr is required to switch refresh rate." >&2
        return 1
      fi

      preferred_output="$(mmsg -g -o 2>/dev/null | awk 'NR==1 {print $1}')"
      mapfile -t mode_lines < <(resolve_output_and_mode "$preferred_output" "$target_hz")

      if [ "''${#mode_lines[@]}" -lt 2 ]; then
        echo "Unable to determine output mode for ''${target_hz}Hz." >&2
        return 1
      fi

      output_name="''${mode_lines[0]}"
      mode_spec="''${mode_lines[1]}"

      if [ -z "$output_name" ] || [ -z "$mode_spec" ]; then
        echo "Output resolution information is incomplete." >&2
        return 1
      fi

      wlr-randr --output "$output_name" --mode "$mode_spec" >/dev/null
    }

    request_osd() {
      local mode="$1"
      ags request --instance ags power-mode "$mode" >/dev/null 2>&1 || true
    }

    get_next_mode() {
      case "$1" in
        ultra-eco) echo "eco" ;;
        eco) echo "balanced" ;;
        balanced) echo "performance" ;;
        performance) echo "ultra-eco" ;;
      esac
    }

    fallback_mode_for_restricted_performance() {
      if [ "$(ac_online)" = "1" ]; then
        echo "balanced"
        return 0
      fi

      local percent
      if percent="$(battery_percent 2>/dev/null)"; then
        if [ "$percent" -lt 10 ]; then
          echo "ultra-eco"
          return 0
        fi
        if [ "$percent" -lt 30 ]; then
          echo "eco"
          return 0
        fi
      fi

      echo "balanced"
    }

    apply_mode() {
      local mode="$1"
      local quiet="$2"
      local target_refresh="120"

      if [ "$mode" = "performance" ] && ! can_enable_performance; then
        echo "Performance mode is disabled below 30% battery while unplugged." >&2
        return 2
      fi

      if [ "$mode" = "ultra-eco" ]; then
        target_refresh="60"
      fi

      sudo -n /run/current-system/sw/bin/power-mode-apply "$mode"

      if ! apply_refresh "$target_refresh"; then
        echo "Failed to apply display refresh for mode '$mode'." >&2
      fi

      save_mode "$mode"
      request_osd "$mode"

      if [ "$quiet" != "1" ]; then
        printf '%s\n' "$mode"
      fi
    }

    print_usage() {
      echo "Usage: power-mode <get|icon|status|set <mode>|next|restore> [--quiet]" >&2
      echo "Modes: ultra-eco, eco, balanced, performance" >&2
    }

    command="''${1:-}"
    case "$command" in
      get)
        get_mode
        ;;
      icon)
        mode_icon "$(get_mode)"
        ;;
      status)
        current_mode="$(get_mode)"
        printf '%s %s\n' "$(mode_icon "$current_mode")" "$(mode_label "$current_mode")"
        ;;
      set)
        if [ "$#" -lt 2 ]; then
          print_usage
          exit 1
        fi

        target_mode="$(normalize_mode "$2")" || {
          echo "Unknown mode: $2" >&2
          exit 1
        }

        quiet="0"
        if [ "''${3:-}" = "--quiet" ]; then
          quiet="1"
        fi

        apply_mode "$target_mode" "$quiet"
        ;;
      next)
        quiet="0"
        if [ "''${2:-}" = "--quiet" ]; then
          quiet="1"
        fi

        current_mode="$(get_mode)"
        target_mode="$(get_next_mode "$current_mode")"
        if [ "$target_mode" = "performance" ] && ! can_enable_performance; then
          target_mode="ultra-eco"
        fi

        apply_mode "$target_mode" "$quiet"
        ;;
      restore)
        quiet="0"
        if [ "''${2:-}" = "--quiet" ]; then
          quiet="1"
        fi

        target_mode="$(get_mode)"
        if [ "$target_mode" = "performance" ] && ! can_enable_performance; then
          target_mode="$(fallback_mode_for_restricted_performance)"
        fi

        apply_mode "$target_mode" "$quiet"
        ;;
      *)
        print_usage
        exit 1
        ;;
    esac
  '';

  power-mode-daemon = pkgs.writeShellScriptBin "power-mode-daemon" ''
    set -u

    POLL_INTERVAL="''${POWER_MODE_POLL_INTERVAL:-15}"

    ac_online() {
      for supply in /sys/class/power_supply/*; do
        [ -d "$supply" ] || continue
        if [ "$(cat "$supply/type" 2>/dev/null || true)" = "Mains" ]; then
          if [ "$(cat "$supply/online" 2>/dev/null || echo 0)" = "1" ]; then
            echo "1"
            return 0
          fi
        fi
      done

      echo "0"
    }

    battery_percent() {
      for supply in /sys/class/power_supply/*; do
        [ -d "$supply" ] || continue
        if [ "$(cat "$supply/type" 2>/dev/null || true)" = "Battery" ] && [ -r "$supply/capacity" ]; then
          cat "$supply/capacity"
          return 0
        fi
      done

      return 1
    }

    previous_ac="$(ac_online)"
    previous_capacity="$(battery_percent 2>/dev/null || true)"

    while true; do
      sleep "$POLL_INTERVAL"

      ac_now="$(ac_online)"
      capacity_now="$(battery_percent 2>/dev/null || true)"
      current_mode="$(power-mode get 2>/dev/null || echo balanced)"

      if [ "$previous_ac" = "0" ] && [ "$ac_now" = "1" ]; then
        if [ "$current_mode" != "performance" ]; then
          power-mode set balanced --quiet >/dev/null 2>&1 || true
        fi
      fi

      if [ "$ac_now" = "0" ] && [ -n "$capacity_now" ] && [ -n "$previous_capacity" ] && [ "$capacity_now" != "$previous_capacity" ]; then
        if [ "$previous_capacity" -gt 10 ] && [ "$capacity_now" -le 10 ]; then
          power-mode set ultra-eco --quiet >/dev/null 2>&1 || true
        elif [ "$previous_capacity" -gt 30 ] && [ "$capacity_now" -le 30 ]; then
          power-mode set eco --quiet >/dev/null 2>&1 || true
        fi
      fi

      previous_ac="$ac_now"
      if [ -n "$capacity_now" ]; then
        previous_capacity="$capacity_now"
      fi
    done
  '';

  mangoConfig = import ./modules/config.nix { inherit lib; };
  keybinds = import ./modules/keybinds.nix { inherit lib; };
  visuals = import ./modules/visuals.nix { inherit lib; };
  layout = import ./modules/layout.nix { inherit lib; };
  autostart = import ./modules/autostart.nix { inherit lib; };
in {
  home.packages = with pkgs; [
    mmsg-scroll
    mmsg-layout-switch
    ags-interactive-center
    screenshot
    screenshot-ocr
    animate-brightness
    power-mode
    power-mode-daemon
    wlr-randr
  ];

  imports = [
    inputs.mango.hmModules.mango
  ];

  wayland.windowManager.mango = {
    enable = true;

    extraConfig = lib.concatStringsSep "\n" [
      mangoConfig
      keybinds
      layout
      visuals
      autostart
    ];
  };
}
