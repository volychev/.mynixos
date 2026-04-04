import { Gtk } from "ags/gtk4"
import GLib from "gi://GLib?version=2.0"
import Gio from "gi://Gio"

type PowerModeName = "ultra-eco" | "eco" | "balanced" | "performance"

const iconByMode: Record<PowerModeName, string> = {
  "ultra-eco": "􀇥",
  eco: "􀥳",
  balanced: "􀊵",
  performance: "􀋦",
}

function normalizeMode(raw: string): PowerModeName {
  const token = raw.trim().toLowerCase()
  switch (token) {
    case "ultra-eco":
    case "ultra_eco":
    case "ultraeco":
    case "ultra":
      return "ultra-eco"
    case "eco":
      return "eco"
    case "balanced":
    case "balance":
      return "balanced"
    case "performance":
    case "perf":
      return "performance"
    default:
      return "balanced"
  }
}

export default function PowerModeIcon() {
  const icon = <label cssClasses={["power-mode-icon"]} label={iconByMode.balanced} /> as Gtk.Label
  icon.halign = Gtk.Align.CENTER
  icon.valign = Gtk.Align.CENTER

  const readCurrentMode = () => {
    const proc = Gio.Subprocess.new(["power-mode", "get"], Gio.SubprocessFlags.STDOUT_PIPE)
    proc.communicate_utf8_async(null, null, (subprocess, asyncResult) => {
      try {
        const [, standardOutput] = subprocess!.communicate_utf8_finish(asyncResult)
        if (!standardOutput) {
          return
        }

        icon.label = iconByMode[normalizeMode(standardOutput)]
      } catch (error) {
        console.error(error)
      }
    })
  }

  const cycleMode = () => {
    Gio.Subprocess.new(["power-mode", "next"], Gio.SubprocessFlags.NONE)
    GLib.timeout_add(GLib.PRIORITY_DEFAULT, 250, () => {
      readCurrentMode()
      return GLib.SOURCE_REMOVE
    })
  }

  const clickController = new Gtk.GestureClick()
  clickController.connect("pressed", () => {
    cycleMode()
  })
  icon.add_controller(clickController)

  const timerId = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 2500, () => {
    readCurrentMode()
    return GLib.SOURCE_CONTINUE
  })

  icon.connect("destroy", () => {
    if (timerId) {
      GLib.source_remove(timerId)
    }
  })

  readCurrentMode()
  return icon
}
