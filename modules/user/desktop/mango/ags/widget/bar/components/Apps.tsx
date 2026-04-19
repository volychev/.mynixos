import { Gtk } from "ags/gtk4";
import Gio from "gi://Gio";
import GLib from "gi://GLib";

let occupiedTagsMask = 0;
let activeTagsMask = 0;
let focusedAppId = "";
let focusedTitle = "";

const updateListeners: (() => void)[] = [];

function execCommand(args: string[]): Promise<string> {
    return new Promise((resolve, reject) => {
        try {
            const proc = Gio.Subprocess.new(args, Gio.SubprocessFlags.STDOUT_PIPE);
            proc.communicate_utf8_async(null, null, (p, res) => {
                try {
                    const [, stdout] = p!.communicate_utf8_finish(res);
                    resolve(stdout?.trim() ?? "");
                } catch (e) {
                    reject(e);
                }
            });
        } catch (e) {
            reject(e);
        }
    });
}

async function initialSync() {
    try {
        const [tagsOutput, clientOutput] = await Promise.all([
            execCommand(["mmsg", "-g", "-t"]),
            execCommand(["mmsg", "-g", "-c"]),
        ]);

        occupiedTagsMask = 0;
        activeTagsMask = 0;

        tagsOutput.split("\n").forEach((line) => {
            const match = line.match(/tag\s+(\d+)\s+(\d+)\s+(\d+)/);
            if (match) {
                const tag = parseInt(match[1], 10);
                const state = parseInt(match[2], 10);
                const clients = parseInt(match[3], 10);

                if (clients > 0) occupiedTagsMask |= 1 << (tag - 1);
                if (state === 1) activeTagsMask |= 1 << (tag - 1);
            }
        });

        const parts = clientOutput.split(" ");
        focusedAppId = parts[0]?.toLowerCase() ?? "";
        focusedTitle = parts.slice(1).join(" ");

        updateListeners.forEach((cb) => cb());
    } catch (e) {
        console.error("MangoWM Sync Error:", e);
    }
}

function handleEvent(line: string) {
    const tagMatch = line.match(/tag\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/);
    if (tagMatch) {
        const tag = parseInt(tagMatch[1], 10);
        const active = parseInt(tagMatch[2], 10);
        const clients = parseInt(tagMatch[3], 10);

        if (clients > 0) {
            occupiedTagsMask |= 1 << (tag - 1);
        } else {
            occupiedTagsMask &= ~(1 << (tag - 1));
        }

        if (active === 1) {
            activeTagsMask = 1 << (tag - 1);
        }

        updateListeners.forEach((cb) => cb());
        return;
    }

    const appMatch = line.match(/appid\s+(.+)/);
    if (appMatch) {
        focusedAppId = appMatch[1].toLowerCase();
        updateListeners.forEach((cb) => cb());
        return;
    }

    const titleMatch = line.match(/title\s+(.+)/);
    if (titleMatch) {
        focusedTitle = titleMatch[1];
        updateListeners.forEach((cb) => cb());
        return;
    }
}

function watchMangoWM() {
    const proc = Gio.Subprocess.new(["mmsg", "-w"], Gio.SubprocessFlags.STDOUT_PIPE);
    const stdout = proc.get_stdout_pipe();

    if (!stdout) return;

    const stream = new Gio.DataInputStream({ base_stream: stdout });

    const read = () => {
        stream.read_line_async(GLib.PRIORITY_DEFAULT, null, (s, res) => {
            try {
                const [line] = s!.read_line_finish_utf8(res);
                if (line !== null) {
                    handleEvent(line);
                    read();
                }
            } catch (e) {
                console.error("Stream Error:", e);
            }
        });
    };

    read();
    initialSync();
}

watchMangoWM();

export default function Workspaces() {
    const container = (<box cssClasses={["workspaces-container"]} spacing={6} />) as Gtk.Box;

    const tags = Array.from({ length: 10 }, (_, i) => {
        const index = i + 1;

        const tagLabel = (<label label={`${index}`} cssClasses={["tag-number"]} />) as Gtk.Label;
        const title = (<label cssClasses={["tag-title"]} />) as Gtk.Label;

        const button = (
            <button
                visible={false}
                onClicked={() => {
                    Gio.Subprocess.new(["mmsg", "-s", "-t", `${index}`], Gio.SubprocessFlags.NONE);
                }}
            >
                <box valign={Gtk.Align.CENTER}>
                    {tagLabel}
                    {title}
                </box>
            </button>
        ) as Gtk.Button;

        return { button, title, index };
    });

    tags.forEach((t) => container.append(t.button));

    const update = () => {
        tags.forEach(({ button, title, index }) => {
            const isOccupied = (occupiedTagsMask & (1 << (index - 1))) !== 0;
            const isActive = (activeTagsMask & (1 << (index - 1))) !== 0;

            button.visible = isOccupied || isActive;

            if (button.visible) {
                button.cssClasses = ["tag-button", isActive ? "active" : ""];

                if (isActive && focusedTitle && isOccupied) {
                    title.visible = true;
                    title.label = focusedTitle.length > 30 
                        ? `${focusedTitle.substring(0, 30)}...` 
                        : focusedTitle;
                } else {
                    title.visible = false;
                }
            }
        });
    };

    updateListeners.push(update);
    update();

    return container;
}
