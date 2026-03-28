import { Gtk, Gdk } from "ags/gtk4"
import Battery from "gi://AstalBattery";

export default function BatteryIcon() {
    const bat = Battery.get_default();
    const fill = <box cssClasses={["battery-fill"]} /> as Gtk.Box;
    const body = <box cssClasses={["battery-body"]}>{fill}</box> as Gtk.Box;
    const percentLabel = <label cssClasses={["battery-percentage"]} /> as Gtk.Label;

    const tip = <box cssClasses={["battery-tip"]} /> as Gtk.Box;
    tip.halign = Gtk.Align.CENTER;
    tip.valign = Gtk.Align.CENTER;

    const overlay = new Gtk.Overlay();
    overlay.set_child(body);
    overlay.set_child(fill); 
    overlay.add_overlay(percentLabel);

    const update = () => {
        const p = Math.floor(bat.percentage * 100);

        percentLabel.label = `${p}`;
        percentLabel.halign = Gtk.Align.CENTER;
        percentLabel.valign = Gtk.Align.CENTER;
        
        const targetHeight = 13; 
        const targetWidth = 24;
        const fillWidth = Math.min(Math.max(7, Math.floor((targetWidth / 100) * p)), targetWidth);

        body.set_size_request(targetWidth, targetHeight);
        fill.set_size_request(fillWidth, targetHeight);
        
        body.valign = Gtk.Align.CENTER;
        fill.valign = Gtk.Align.CENTER;
        
        const context = fill.get_style_context();
        if (bat.charging) {
            context.add_class("charging");
        } else {
            context.remove_class("charging");
        }

        if (p < 20 && !bat.charging) {
            context.add_class("low");
        } else {
            context.remove_class("low");
        }
    };

    bat.connect("notify::percentage", update);
    bat.connect("notify::charging", update);

    update();

    return (
        <box cssClasses={["battery-container"]}>
            {overlay}
            {tip}
        </box>
    );
}