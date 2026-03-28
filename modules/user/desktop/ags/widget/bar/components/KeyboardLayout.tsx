import { Gtk } from "ags/gtk4";
import GLib from "gi://GLib?version=2.0";
import { execAsync } from "ags/process";

export default function KeyboardLayoutIcon() {
    const icon = <label cssClasses={["layout-icon"]} /> as Gtk.Label;

    icon.halign = Gtk.Align.CENTER;
    icon.valign = Gtk.Align.CENTER;

    const update = () => {
        // Получаем раскладку
        execAsync("mmsg -g -k")
            .then((layoutOutput) => {
                // Получаем статус Caps Lock напрямую из системы
                execAsync("bash -c \"cat /sys/class/leds/*capslock/brightness | head -n 1\"")
                    .then((capsOutput) => {
                        const parts = layoutOutput.trim().split(" ");
                        let currentLayout = parts[parts.length - 1];

                        // Заменяем us на en для красоты
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

    // Обновляем данные каждые 500 миллисекунд
    GLib.timeout_add(GLib.PRIORITY_DEFAULT, 500, () => {
        update();
        return GLib.SOURCE_CONTINUE;
    });

    // Первичный вызов при инициализации
    update();

    return (
        <box cssClasses={["layout-container"]}>
            {icon}
        </box>
    );
}