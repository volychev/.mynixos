import { Gtk, Gdk } from "ags/gtk4"

export default function Separator() {
    const separator = <box cssClasses={["separator"]} /> as Gtk.Box;
    separator.halign = Gtk.Align.CENTER;
    separator.valign = Gtk.Align.CENTER;

    return (
        separator
    );
}