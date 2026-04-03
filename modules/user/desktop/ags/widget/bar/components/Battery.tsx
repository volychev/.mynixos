import { Gtk } from "ags/gtk4"
import Battery from "gi://AstalBattery";

export default function BatteryIcon() {
    const bat = Battery.get_default();
    const fill = <box cssClasses={["battery-fill"]} /> as Gtk.Box;
    const body = <box cssClasses={["battery-body"]} /> as Gtk.Box;
    const percentLabel = <label cssClasses={["battery-percentage"]} /> as Gtk.Label;

    const tip = <box cssClasses={["battery-tip"]} /> as Gtk.Box;
    tip.halign = Gtk.Align.CENTER;
    tip.valign = Gtk.Align.CENTER;

    body.append(fill);

    const overlay = new Gtk.Overlay();
    overlay.set_child(body);
    overlay.add_overlay(percentLabel);
    overlay.set_clip_overlay(percentLabel, false);
    overlay.set_measure_overlay(percentLabel, false);
    fill.halign = Gtk.Align.START;
    fill.valign = Gtk.Align.FILL;

    const update = () => {
        const p = Math.round(Math.max(0, Math.min(1, bat.percentage)) * 100);

        percentLabel.label = `${p}`;
        percentLabel.halign = Gtk.Align.CENTER;
        percentLabel.valign = Gtk.Align.CENTER;

        const targetHeight = 13;
        const targetWidth = 24;
        const innerHeight = targetHeight - 2;
        const innerWidth = targetWidth - 2;
        const proportionalWidth = Math.floor((innerWidth * p) / 100);
        const fillWidth = p > 0 ? Math.min(Math.max(proportionalWidth, 2), innerWidth) : 0;

        body.set_size_request(targetWidth, targetHeight);
        body.set_overflow(Gtk.Overflow.HIDDEN);

        fill.margin_top = 1;
        fill.margin_bottom = 1;
        fill.margin_start = 1;
        fill.margin_end = 1;
        fill.set_size_request(fillWidth, innerHeight);

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
