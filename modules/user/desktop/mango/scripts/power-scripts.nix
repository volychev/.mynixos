{ pkgs }:
let
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

  screen-idle-dim-brightness = pkgs.writeShellScriptBin "screen-idle-dim-brightness" ''
    set -eu

    STATE_DIR="''${XDG_RUNTIME_DIR:-/tmp}/screen-idle-daemon"
    BRIGHTNESS_FILE="$STATE_DIR/brightness-before-dim"
    BC_BIN="${pkgs.brightnessctl}/bin/brightnessctl"
    ANIMATE_BIN="${animate-brightness}/bin/animate-brightness"
    TARGET_PERCENT="''${SCREEN_IDLE_DIM_TARGET_PERCENT:-1}"

    mkdir -p "$STATE_DIR"

    case "$TARGET_PERCENT" in
      *[!0-9]*)
        echo "SCREEN_IDLE_DIM_TARGET_PERCENT must be an integer between 1 and 100." >&2
        exit 1
        ;;
    esac

    if [ -z "$TARGET_PERCENT" ]; then
      echo "SCREEN_IDLE_DIM_TARGET_PERCENT must be an integer between 1 and 100." >&2
      exit 1
    fi

    if [ "$TARGET_PERCENT" -lt 1 ] || [ "$TARGET_PERCENT" -gt 100 ]; then
      echo "SCREEN_IDLE_DIM_TARGET_PERCENT must be between 1 and 100." >&2
      exit 1
    fi

    max="$($BC_BIN m)"
    current="$($BC_BIN g)"
    if [ "$max" -le 0 ]; then
      echo "brightnessctl returned an invalid max brightness value." >&2
      exit 1
    fi

    current_pct=$(( current * 100 / max ))
    if [ "$current_pct" -le "$TARGET_PERCENT" ]; then
      exit 0
    fi

    # Save latest user brightness every dim cycle, so restore always returns
    # to the value before current idle dim.
    printf '%s\n' "$current_pct" > "$BRIGHTNESS_FILE"
    "$ANIMATE_BIN" "$TARGET_PERCENT"
  '';

  screen-idle-restore-brightness = pkgs.writeShellScriptBin "screen-idle-restore-brightness" ''
    set -eu

    STATE_DIR="''${XDG_RUNTIME_DIR:-/tmp}/screen-idle-daemon"
    BRIGHTNESS_FILE="$STATE_DIR/brightness-before-dim"
    ANIMATE_BIN="${animate-brightness}/bin/animate-brightness"

    if [ ! -r "$BRIGHTNESS_FILE" ]; then
      exit 0
    fi

    saved_pct="$(tr -d '[:space:]' < "$BRIGHTNESS_FILE")"
    rm -f "$BRIGHTNESS_FILE"

    case "$saved_pct" in
      *[!0-9]*)
        echo "Stored idle brightness value is invalid: '$saved_pct'." >&2
        exit 1
        ;;
    esac

    if [ -z "$saved_pct" ]; then
      echo "Stored idle brightness value is invalid: empty value." >&2
      exit 1
    fi

    if [ "$saved_pct" -lt 1 ]; then
      saved_pct=1
    elif [ "$saved_pct" -gt 100 ]; then
      saved_pct=100
    fi

    "$ANIMATE_BIN" "$saved_pct"
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
        ultra-eco) echo "􀇥" ;;
        eco) echo "􀥳" ;;
        balanced) echo "􀊵" ;;
        performance) echo "􀋦" ;;
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

    mode_idle_timeout_seconds() {
      case "$1" in
        ultra-eco) echo "120" ;;
        eco) echo "300" ;;
        balanced) echo "1800" ;;
        performance) echo "7200" ;;
        *)
          return 1
          ;;
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
      echo "Usage: power-mode <get|icon|status|idle-timeout [mode]|set <mode>|next|restore> [--quiet]" >&2
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
      idle-timeout)
        if [ "$#" -eq 2 ]; then
          timeout_mode="$(normalize_mode "$2")" || {
            echo "Unknown mode: $2" >&2
            exit 1
          }
        elif [ "$#" -eq 1 ]; then
          timeout_mode="$(get_mode)"
        else
          print_usage
          exit 1
        fi

        mode_idle_timeout_seconds "$timeout_mode"
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

  screen-idle-daemon = pkgs.writeShellScriptBin "screen-idle-daemon" ''
    set -eu

    POLL_INTERVAL="''${SCREEN_IDLE_POLL_INTERVAL:-2}"
    PRE_DIM_SECONDS="''${SCREEN_IDLE_PRE_DIM_SECONDS:-15}"
    SWAYIDLE_BIN="${pkgs.swayidle}/bin/swayidle"
    WLOPM_BIN="${pkgs.wlopm}/bin/wlopm"
    PRE_DIM_BIN="${screen-idle-dim-brightness}/bin/screen-idle-dim-brightness"
    RESTORE_BRIGHTNESS_BIN="${screen-idle-restore-brightness}/bin/screen-idle-restore-brightness"

    get_timeout_seconds() {
      local mode
      mode="$(power-mode get 2>/dev/null || echo balanced)"
      power-mode idle-timeout "$mode" 2>/dev/null || echo "1800"
    }

    start_swayidle() {
      local timeout="$1"
      local dim_timeout
      local -a swayidle_cmd=("$SWAYIDLE_BIN" -w)

      if [ "$timeout" -gt "$PRE_DIM_SECONDS" ]; then
        dim_timeout=$((timeout - PRE_DIM_SECONDS))
        swayidle_cmd+=(
          timeout "$dim_timeout" "$PRE_DIM_BIN"
          resume "$RESTORE_BRIGHTNESS_BIN"
        )
      fi

      swayidle_cmd+=(
        timeout "$timeout" "$WLOPM_BIN --off '*'"
        resume "$WLOPM_BIN --on '*' && $RESTORE_BRIGHTNESS_BIN"
        before-sleep "$WLOPM_BIN --off '*'"
      )

      "''${swayidle_cmd[@]}" &
      swayidle_pid="$!"
    }

    stop_swayidle() {
      if [ -n "''${swayidle_pid:-}" ] && kill -0 "$swayidle_pid" 2>/dev/null; then
        kill "$swayidle_pid"
        wait "$swayidle_pid" 2>/dev/null || true
      fi
      swayidle_pid=""
    }

    cleanup() {
      stop_swayidle
    }

    trap cleanup EXIT INT TERM

    current_timeout=""
    swayidle_pid=""

    while true; do
      timeout="$(get_timeout_seconds)"

      if [ "$timeout" != "$current_timeout" ] || [ -z "$swayidle_pid" ] || ! kill -0 "$swayidle_pid" 2>/dev/null; then
        stop_swayidle
        start_swayidle "$timeout"
        current_timeout="$timeout"
      fi

      sleep "$POLL_INTERVAL"
    done
  '';

  power-mode-keychord-enter = pkgs.writeShellScriptBin "power-mode-keychord-enter" ''
    set -eu

    STATE_DIR="''${XDG_RUNTIME_DIR:-/tmp}/power-mode-keychord"
    TIMER_PID_FILE="$STATE_DIR/timer.pid"
    CHORD_TIMEOUT_SECONDS="''${POWER_MODE_KEYCHORD_TIMEOUT_SECONDS:-2}"

    mkdir -p "$STATE_DIR"

    if [ -r "$TIMER_PID_FILE" ]; then
      old_pid="$(tr -d '[:space:]' < "$TIMER_PID_FILE")"
      case "$old_pid" in
        *[!0-9]*|"")
          ;;
        *)
          if kill -0 "$old_pid" 2>/dev/null; then
            kill "$old_pid"
          fi
          ;;
      esac
      rm -f "$TIMER_PID_FILE"
    fi

    mmsg -d setkeymode,power

    (
      sleep "$CHORD_TIMEOUT_SECONDS"
      mmsg -d setkeymode,default >/dev/null 2>&1 || true
    ) &
    printf '%s\n' "$!" > "$TIMER_PID_FILE"
  '';

  power-mode-keychord-select = pkgs.writeShellScriptBin "power-mode-keychord-select" ''
    set -eu

    if [ "$#" -ne 1 ]; then
      echo "Usage: power-mode-keychord-select <1|2|3|4>" >&2
      exit 1
    fi

    case "$1" in
      1) mode="ultra-eco" ;;
      2) mode="eco" ;;
      3) mode="balanced" ;;
      4) mode="performance" ;;
      *)
        echo "Selection must be 1, 2, 3 or 4." >&2
        exit 1
        ;;
    esac

    cleanup() {
      mmsg -d setkeymode,default >/dev/null 2>&1 || true
      STATE_DIR="''${XDG_RUNTIME_DIR:-/tmp}/power-mode-keychord"
      TIMER_PID_FILE="$STATE_DIR/timer.pid"
      if [ -r "$TIMER_PID_FILE" ]; then
        timer_pid="$(tr -d '[:space:]' < "$TIMER_PID_FILE")"
        case "$timer_pid" in
          *[!0-9]*|"")
            ;;
          *)
            if kill -0 "$timer_pid" 2>/dev/null; then
              kill "$timer_pid"
            fi
            ;;
        esac
        rm -f "$TIMER_PID_FILE"
      fi
    }

    trap cleanup EXIT INT TERM
    power-mode set "$mode" --quiet
  '';
in {
  inherit
    animate-brightness
    power-mode
    screen-idle-daemon
    power-mode-keychord-enter
    power-mode-keychord-select
    ;
}
