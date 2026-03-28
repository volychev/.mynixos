import { Gtk } from "ags/gtk4";
import Wp from "gi://AstalWp";

export default function AudioIcon() {
    const speaker = Wp.get_default()?.audio.default_speaker;
    
    const icon = <label cssClasses={["audio-icon"]} /> as Gtk.Label;

    const update = () => {
        if (!speaker) {
            return;
        }

        icon.halign = Gtk.Align.CENTER;
        icon.valign = Gtk.Align.CENTER;

        const volume = speaker.volume * 100;
        const isMuted = speaker.mute;

        if (isMuted || volume === 0) {
            icon.label = "􀊣"; 
        } else {
            if (volume > 67) {
                icon.label = "􀊩";     
            } else if (volume > 33) {
                icon.label = "􀊧"; 
            } else {
                icon.label = "􀊥"; 
            }
        }
    };

    if (speaker) {
        speaker.connect("notify::volume", update);
        speaker.connect("notify::mute", update);
    }

    update();
    
    return (
        <button
            cssClasses={["audio-button"]} 
            onClicked={() => {
                speaker.mute = !speaker.mute;
            }}
        >
            {icon}
        </button>
    );
}