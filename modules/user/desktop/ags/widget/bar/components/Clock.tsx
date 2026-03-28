import { Gtk, Gdk } from "ags/gtk4"
import { createPoll } from "ags/time"

export default function Clock() {
    const clock = createPoll("", 60 * 1000, 'date +"%a %e, %H:%M"')

    return (
        <box cssClasses={["clock-container"]}>
            <label label={clock} />
        </box>
    );
}