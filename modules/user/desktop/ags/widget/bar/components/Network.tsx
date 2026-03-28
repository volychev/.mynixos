import { Gtk } from "ags/gtk4";
import Network from "gi://AstalNetwork";
import GLib from "gi://GLib?version=2.0";

export default function WifiIcon() {
    const network = Network.get_default();
    const icon = <label cssClasses={["wifi-icon"]} /> as Gtk.Label;

    const update = () => {
        const wifi = network.wifi;

        icon.halign = Gtk.Align.CENTER;
        icon.valign = Gtk.Align.CENTER;

        if (!wifi) {
            icon.label = "􀙈";
            return;
        }

        const strength = wifi.strength;

        if (strength > 25) {
            icon.label = "􀙇";
        } else if (strength > 0) {
            icon.label = "􀙥"; 
        } else {
            icon.label = "􀙈";
        }
    };
    
    network.connect("notify::wifi", update);

    if (network.wifi) {
        network.wifi.connect("notify::strength", update);
    }

    const clickController = new Gtk.GestureClick();
    clickController.connect("pressed", () => {
        GLib.spawn_command_line_async("kitty -- nmtui");
    });
    icon.add_controller(clickController);

    update();
    return icon;
}