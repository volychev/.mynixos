import { Gtk } from "ags/gtk4";
import Bluetooth from "gi://AstalBluetooth";
import GLib from "gi://GLib";

export default function BluetoothIcon() {
    const bluetooth = Bluetooth.get_default();
    const icon = <label cssClasses={["bluetooth-icon"]} /> as Gtk.Label;

    const update = () => {
        icon.halign = Gtk.Align.CENTER;
        icon.valign = Gtk.Align.CENTER;

        if (bluetooth.is_powered && bluetooth.is_connected) {
            icon.label = "􁄡"; 
            icon.remove_css_class("disabled");
        } else {
            icon.label = ""; 
            icon.add_css_class("disabled");
        }
    };
    
    bluetooth.connect("notify::is-powered", update);
    bluetooth.connect("notify::is-connected", update);

    const clickController = new Gtk.GestureClick();
    clickController.connect("pressed", () => {
        GLib.spawn_command_line_async("blueman-manager");
    });
    icon.add_controller(clickController);

    update();
    return icon;
}