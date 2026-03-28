import { Gtk } from "ags/gtk4";
import GLib from "gi://GLib?version=2.0";
import { execAsync } from "ags/process";

export default function KeyboardLayoutIcon() {
    const icon = <label cssClasses={["layout-icon"]} /> as Gtk.Label;

    icon.halign = Gtk.Align.CENTER;
    icon.valign = Gtk.Align.CENTER;

    const update = () => {
        execAsync("mmsg -g -k")
            .then((layoutOutput) => {
                execAsync("bash -c \"cat /sys/class/leds/*capslock/brightness | head -n 1\"")
                    .then((capsOutput) => {
                        const parts = layoutOutput.trim().split(" ");
                        let currentLayout = parts[parts.length - 1];

                        if (currentLayout === "us") {
                            currentLayout = "en";
                        }

                        const isCapsOn = capsOutput.trim() === "1";

                        if (isCapsOn) {
                            icon.label = currentLayout.toUpperCase();
                        } else {
                            icon.label = currentLayout.toLowerCase();
                        }
                    })
                    .catch((error) => {
                        console.error(error);
                    });
            })
            .catch((error) => {
                console.error(error);
            });
    };

    GLib.timeout_add(GLib.PRIORITY_DEFAULT, 2000, () => {
        update();
        return GLib.SOURCE_CONTINUE;
    });

    update();

    return (
        <box cssClasses={["layout-container"]}>
            {icon}
        </box>
    );
}