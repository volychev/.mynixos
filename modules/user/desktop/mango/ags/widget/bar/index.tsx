import app from "ags/gtk4/app"
import { Astal, Gtk, Gdk } from "ags/gtk4"

import BatteryIcon from "./components/Battery"
import Clock from "./components/Clock"
import Separator from "./components/Separator"
import WifiIcon from "./components/Network"
import VpnIndicator from "./components/Vpn"
import AudioIcon from "./components/Audio"
import Workspaces from "./components/Apps"
import InteractiveCenter from "./components/InteractiveCenter"
import BluetoothIcon from "./components/Bluetooth"
import TrayModule from "./components/Tray"
import KeyboardLayoutIcon from "./components/KeyboardLayout"
import PowerModeIcon from "./components/PowerMode"

export default function Bar(gdkmonitor: Gdk.Monitor) {
  const { TOP, LEFT, RIGHT } = Astal.WindowAnchor

  const window = <window
      visible
      name="bar"
      class="Bar"
      gdkmonitor={gdkmonitor}
      exclusivity={Astal.Exclusivity.EXCLUSIVE}
      keymode={Astal.Keymode.ON_DEMAND}
      anchor={TOP | LEFT | RIGHT}
      focusable={true}
      heightRequest={31}
      application={app}
    >
      <centerbox
        start_widget={
          <box class="startbox" halign={Gtk.Align.START}>
            <Workspaces />
          </box>
        }
        center_widget={
          <box class="middlebox" halign={Gtk.Align.CENTER}>
            <InteractiveCenter />
          </box>
        }
        end_widget={
          <box class="endbox" halign={Gtk.Align.END}>
            <KeyboardLayoutIcon    />
            {/* <TrayModule />  */}
            <WifiIcon />
            <VpnIndicator />
            <BluetoothIcon />
            <AudioIcon />
            <PowerModeIcon />
            <BatteryIcon />
            <Separator />
            <Clock />
          </box>
        }
      />
    </window>;
  return window;
}
