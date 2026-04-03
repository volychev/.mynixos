import { Gtk } from "ags/gtk4";
import GLib from "gi://GLib?version=2.0";
import { execAsync } from "ags/process";

function readLayout(layoutOutput: string) {
    const parts = layoutOutput.trim().split(/\s+/);
    const layoutToken = parts[parts.length - 1]?.toLowerCase() ?? "us";
    return layoutToken === "us" ? "en" : layoutToken;
}

export default function KeyboardLayoutIcon() {
    const icon = <label cssClasses={["layout-icon"]} /> as Gtk.Label;
    icon.halign = Gtk.Align.CENTER;
    icon.valign = Gtk.Align.CENTER;

    const update = () => {
        execAsync(["mmsg", "-g", "-k"])
            .then((layoutOutput) => {
                const currentLayout = readLayout(layoutOutput);
                return execAsync(["bash", "-c", "cat /sys/class/leds/*capslock/brightness 2>/dev/null | head -n 1"]).then(
                    (capsOutput) => {
                        const capsEnabled = capsOutput.trim() === "1";
                        icon.label = capsEnabled ? currentLayout.toUpperCase() : currentLayout.toLowerCase();
                    },
                );
            })
            .catch((error) => {
                console.error(error);
            });
    };

    const timerId = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 1200, () => {
        update();
        return GLib.SOURCE_CONTINUE;
    });

    icon.connect("destroy", () => {
        if (timerId) {
            GLib.source_remove(timerId);
        }
    });

    update();

    return (
        <box cssClasses={["layout-container"]}>
            {icon}
        </box>
    );
}
